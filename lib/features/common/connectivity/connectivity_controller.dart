import 'package:hiddify/data/data_providers.dart';
import 'package:hiddify/domain/connectivity/connectivity.dart';
import 'package:hiddify/domain/core_facade.dart';
import 'package:hiddify/features/common/active_profile/active_profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'connectivity_controller.g.dart';

@Riverpod(keepAlive: true)
class ConnectivityController extends _$ConnectivityController with AppLogger {
  @override
  Stream<ConnectionStatus> build() {
    ref.listen(
      activeProfileProvider.select((value) => value.asData?.value),
      (previous, next) async {
        if (previous == null) return;
        final shouldReconnect = previous != next;
        if (shouldReconnect) {
          await reconnect(next?.id);
        }
      },
    );
    return _core.watchConnectionStatus().doOnData((event) {
      loggy.info("connection status: ${event.format()}");
    });
  }

  CoreFacade get _core => ref.watch(coreFacadeProvider);

  Future<void> toggleConnection() async {
    if (state case AsyncError()) {
      await _connect();
    } else if (state case AsyncData(:final value)) {
      switch (value) {
        case Disconnected():
          await _connect();
        case Connected():
          await _disconnect();
        default:
          loggy.warning("switching status, debounce");
      }
    }
  }

  Future<void> reconnect(String? profileId) async {
    if (state case AsyncData(:final value) when value == const Connected()) {
      if (profileId == null) {
        return _disconnect();
      }
      loggy.debug("reconnecting, profile: [$profileId]");
      await _core.restart(profileId).mapLeft((err) {
        loggy.warning("error reconnecting", err);
        state = AsyncError(err, StackTrace.current);
      }).run();
    }
  }

  Future<void> abortConnection() async {
    if (state case AsyncData(:final value)) {
      switch (value) {
        case Connected() || Connecting():
          loggy.debug("aborting connection");
          await _disconnect();
        default:
      }
    }
  }

  /// Rebuilds the entire tunnel after the default physical network changed.
  ///
  /// A Wi-Fi <-> cellular switch abandons every outbound socket built on the
  /// old network and invalidates the one-shot `protectProcessNet()` call. A
  /// plain `restart()` is not enough: it only restarts the Go core and does
  /// not recreate the TUN, so the new sockets stay unprotected. A full
  /// stop/start destroys and recreates the VPN session on the new network.
  bool _rebuilding = false;

  Future<void> rebuildAfterNetworkChange() async {
    if (_rebuilding) return;
    if (state case AsyncData(:final value) when value == const Connected()) {
      _rebuilding = true;
      try {
        loggy.info("network changed, rebuilding the VPN tunnel");
        await _core.stop().run();
        // Give the system time to tear the old VPN session down before a new
        // one is requested; otherwise the extension can observe a stale fd.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final activeProfile = await ref.read(activeProfileProvider.future);
        if (activeProfile == null) return;
        final first = await _core.start(activeProfile.id).run();
        if (first.isLeft()) {
          // The new physical network may still be coming up. Retry once.
          loggy.warning("first rebuild attempt failed, retrying");
          await Future<void>.delayed(const Duration(seconds: 2));
          await _core.start(activeProfile.id).run();
        }
      } finally {
        _rebuilding = false;
      }
    }
  }

  Future<void> _connect() async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    await _core.start(activeProfile!.id).mapLeft((err) {
      loggy.warning("error connecting", err);
      state = AsyncError(err, StackTrace.current);
    }).run();
  }

  Future<void> _disconnect() async {
    await _core.stop().mapLeft((err) {
      loggy.warning("error disconnecting", err);
      state = AsyncError(err, StackTrace.current);
    }).run();
  }
}

@Riverpod(keepAlive: true)
Future<bool> serviceRunning(ServiceRunningRef ref) => ref
    .watch(
      connectivityControllerProvider.selectAsync((data) => data.isConnected),
    )
    .onError((error, stackTrace) => false);
