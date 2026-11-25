import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:combine/combine.dart';
import 'package:ffi/ffi.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/domain/connectivity/connectivity.dart';
import 'package:hiddify/domain/singbox/config_options.dart';
import 'package:hiddify/gen/singbox_generated_bindings.dart';
import 'package:hiddify/services/singbox/ohos_vpn_bridge.dart';
import 'package:hiddify/services/singbox/shared.dart';
import 'package:hiddify/services/singbox/singbox_service.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:loggy/loggy.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

final _logger = Loggy('FFISingboxService');

class FFISingboxService
    with ServiceStatus, InfraLogger
    implements SingboxService {
  static final SingboxNativeLibrary _box = _gen();

  late final ValueStream<ConnectionStatus> _connectionStatus;
  late final ReceivePort _connectionStatusReceiver;
  Stream<String>? _statusStream;
  Stream<String>? _groupsStream;

  static SingboxNativeLibrary _gen() {
    String libName;
    if (Platform.isWindows) {
      libName = "libcore.dll";
    } else if (Platform.isMacOS) {
      libName = "libcore.dylib";
    } else {
      libName = "libcore.so";
    }

    // OHOS adapt: 鸿蒙上 dlopen 的搜索路径不含应用 libs 目录，
    // 依次尝试多个候选路径（相对名 / 应用沙箱绝对路径）。
    final candidates = <String>[
      if (Platform.environment.containsKey('FLUTTER_TEST')) p.join("libcore", libName),
      libName,
      p.join("/data/app", libName),
    ];
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      final execDir = p.dirname(Platform.resolvedExecutable);
      candidates.add(p.join(execDir, "libs", "arm64-v8a", libName));
      candidates.add(p.join(execDir, "libs", "arm64", libName));
      candidates.add(p.join(execDir, libName));
    }

    DynamicLibrary? lib;
    for (final candidate in candidates) {
      try {
        lib = DynamicLibrary.open(candidate);
        _logger.debug('singbox native libs path: "$candidate"');
        break;
      } catch (e) {
        _logger.debug('failed to open singbox native lib at "$candidate": $e');
      }
    }
    if (lib == null) {
      throw StateError('Failed to load $libName from candidates: $candidates');
    }
    return SingboxNativeLibrary(lib);
  }

  @override
  Future<void> init() async {
    loggy.debug("initializing");
    _connectionStatusReceiver = ReceivePort('service status receiver');
    final source = _connectionStatusReceiver
        .asBroadcastStream()
        .map((event) => jsonDecode(event as String) as Map<String, dynamic>)
        .map(mapEventToStatus);
    _connectionStatus = ValueConnectableStream.seeded(
      source,
      const ConnectionStatus.disconnected(),
    ).autoConnect();
  }

  @override
  TaskEither<String, Unit> setup(
    String baseDir,
    String workingDir,
    String tempDir,
  ) {
    final port = _connectionStatusReceiver.sendPort.nativePort;
    return TaskEither(
      () => CombineWorker().execute(
        () {
          _box.setupOnce(NativeApi.initializeApiDLData);
          _box.setup(
            baseDir.toNativeUtf8().cast(),
            workingDir.toNativeUtf8().cast(),
            tempDir.toNativeUtf8().cast(),
            port,
          );
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> parseConfig(
    String path,
    String tempPath,
    bool debug,
  ) {
    return TaskEither(
      () => CombineWorker().execute(
        () {
          final err = _box
              .parse(
                path.toNativeUtf8().cast(),
                tempPath.toNativeUtf8().cast(),
                debug ? 1 : 0,
              )
              .cast<Utf8>()
              .toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> changeConfigOptions(ConfigOptions options) {
    return TaskEither(
      () => CombineWorker().execute(
        () {
          final json = jsonEncode(options.toJson());
          final err = _box
              .changeConfigOptions(json.toNativeUtf8().cast())
              .cast<Utf8>()
              .toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> start(String configPath) {
    return TaskEither(
      () async {
        // OHOS adapt: the system VPN extension owns the TUN device, so ask
        // it for the file descriptor and hand it to the core before the core
        // starts reading from the tunnel.
        //
        // The platform channel call has to be issued on the root isolate. A
        // background isolate has no binary messenger attached to it, so an
        // `invokeMethod` sent from the worker would never be answered and the
        // call would sit there until it times out.
        var tunFd = -1;
        if (OhosVpnBridge.isSupported) {
          try {
            tunFd = await OhosVpnBridge.instance.prepare();
          } catch (e) {
            _logger.error('failed to prepare the vpn tunnel: $e');
            return left('failed to prepare the vpn tunnel: $e');
          }
        }
        return await CombineWorker().execute<Either<String, Unit>>(
          () {
            if (tunFd > 0) {
              _box.setTunFd(tunFd);
            }
            final err = _box
                .start(configPath.toNativeUtf8().cast())
                .cast<Utf8>()
                .toDartString();
            if (err.isNotEmpty) {
              return left(err);
            }
            return right(unit);
          },
        );
      },
    );
  }

  @override
  TaskEither<String, Unit> stop() {
    return TaskEither(
      () async {
        // OHOS adapt: the stats / groups command streams are bound to the
        // core instance that is about to go away. Keeping them cached makes
        // every later start silently reuse a dead stream, which is why node
        // delays stayed empty (and auto selection never ran) after the first
        // stop/start cycle.
        _statusStream = null;
        _groupsStream = null;
        final result =
            await CombineWorker().execute<Either<String, Unit>>(() {
          try {
            _box.stopCommandClient(1).cast<Utf8>().toDartString();
            _box.stopCommandClient(4).cast<Utf8>().toDartString();
          } catch (e) {
            _logger.debug('failed to stop command clients: $e');
          }
          final err = _box.stop().cast<Utf8>().toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          if (OhosVpnBridge.isSupported) {
            _box.clearTunFd();
          }
          return right(unit);
        });
        // OHOS adapt: tear the system VPN extension down once the core
        // stopped reading from the tunnel. The platform channel call has to
        // be issued on the root isolate, see `start` above.
        if (OhosVpnBridge.isSupported) {
          await OhosVpnBridge.instance.stop();
        }
        return result;
      },
    );
  }

  @override
  TaskEither<String, Unit> restart(String configPath) {
    return TaskEither(
      () async {
        if (!OhosVpnBridge.isSupported) {
          return await CombineWorker().execute<Either<String, Unit>>(() {
            final err = _box
                .restart(configPath.toNativeUtf8().cast())
                .cast<Utf8>()
                .toDartString();
            if (err.isNotEmpty) {
              return left(err);
            }
            return right(unit);
          });
        }

        // OHOS adapt: the system VPN extension owns the tunnel, and asking it
        // for a descriptor always tears the old one down first. A bare core
        // restart keeps reading the previous (already closed) descriptor, so
        // the tunnel stayed dead after a network switch or a profile change.
        // Stop the core, rebuild the tunnel, then cold start with the fresh
        // descriptor.
        _statusStream = null;
        _groupsStream = null;
        final stopResult =
            await CombineWorker().execute<Either<String, Unit>>(() {
          try {
            _box.stopCommandClient(1).cast<Utf8>().toDartString();
            _box.stopCommandClient(4).cast<Utf8>().toDartString();
          } catch (e) {
            _logger.debug('failed to stop command clients: $e');
          }
          final err = _box.stop().cast<Utf8>().toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          return right(unit);
        });
        stopResult.match(
          (e) => _logger.error('core did not stop cleanly before restart: $e'),
          (_) => unit,
        );
        _box.clearTunFd();

        int tunFd;
        try {
          tunFd = await OhosVpnBridge.instance.prepare();
        } catch (e) {
          _logger.error('failed to rebuild the vpn tunnel on restart: $e');
          return left('failed to rebuild the vpn tunnel: $e');
        }

        return await CombineWorker().execute<Either<String, Unit>>(() {
          if (tunFd > 0) {
            _box.setTunFd(tunFd);
          }
          final err = _box
              .start(configPath.toNativeUtf8().cast())
              .cast<Utf8>()
              .toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          return right(unit);
        });
      },
    );
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() => _connectionStatus;

  @override
  Stream<String> watchStats() {
    if (_statusStream != null) return _statusStream!;
    final receiver = ReceivePort('status receiver');
    final statusStream = receiver.asBroadcastStream(
      onCancel: (_) {
        _logger.debug("stopping status command client");
        final err = _box.stopCommandClient(1).cast<Utf8>().toDartString();
        if (err.isNotEmpty) {
          _logger.error("error stopping status client");
        }
        receiver.close();
        _statusStream = null;
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            loggy.error("[status client] error received: $event");
            throw event.replaceFirst('error:', "");
          }
          return event;
        }
        loggy.error("[status client] unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    final err = _box
        .startCommandClient(1, receiver.sendPort.nativePort)
        .cast<Utf8>()
        .toDartString();
    if (err.isNotEmpty) {
      loggy.error("error starting status command: $err");
      throw err;
    }

    return _statusStream = statusStream;
  }

  @override
  Stream<String> watchOutbounds() {
    if (_groupsStream != null) return _groupsStream!;
    final receiver = ReceivePort('outbounds receiver');
    final groupsStream = receiver.asBroadcastStream(
      onCancel: (_) {
        _logger.debug("stopping group command client");
        final err = _box.stopCommandClient(4).cast<Utf8>().toDartString();
        if (err.isNotEmpty) {
          _logger.error("error stopping group client");
        }
        receiver.close();
        _groupsStream = null;
      },
    ).map(
      (event) {
        if (event case String _) {
          if (event.startsWith('error:')) {
            loggy.error("[group client] error received: $event");
            throw event.replaceFirst('error:', "");
          }
          return event;
        }
        loggy.error("[group client] unexpected type, msg: $event");
        throw "invalid type";
      },
    );

    final err = _box
        .startCommandClient(4, receiver.sendPort.nativePort)
        .cast<Utf8>()
        .toDartString();
    if (err.isNotEmpty) {
      loggy.error("error starting group command: $err");
      throw err;
    }

    return _groupsStream = groupsStream;
  }

  @override
  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag) {
    return TaskEither(
      () => CombineWorker().execute(
        () {
          final err = _box
              .selectOutbound(
                groupTag.toNativeUtf8().cast(),
                outboundTag.toNativeUtf8().cast(),
              )
              .cast<Utf8>()
              .toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  TaskEither<String, Unit> urlTest(String groupTag) {
    return TaskEither(
      () => CombineWorker().execute(
        () {
          final err = _box
              .urlTest(groupTag.toNativeUtf8().cast())
              .cast<Utf8>()
              .toDartString();
          if (err.isNotEmpty) {
            return left(err);
          }
          return right(unit);
        },
      ),
    );
  }

  @override
  Stream<String> watchLogs(String path) {
    var linesRead = 0;
    return Stream.periodic(
      const Duration(seconds: 1),
    ).asyncMap((_) async {
      final result = await _readLogs(path, linesRead);
      linesRead = result.$2;
      return result.$1;
    }).transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          for (final item in data) {
            sink.add(item);
          }
        },
      ),
    );
  }

  Future<(List<String>, int)> _readLogs(String path, int from) async {
    return CombineWorker().execute(
      () async {
        final lines = await File(path).readAsLines();
        final to = lines.length;
        return (lines.sublist(from), to);
      },
    );
  }
}
