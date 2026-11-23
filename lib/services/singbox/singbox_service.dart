import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/domain/connectivity/connectivity.dart';
import 'package:hiddify/domain/singbox/singbox.dart';
import 'package:hiddify/services/singbox/ffi_singbox_service.dart';
import 'package:hiddify/services/singbox/mobile_singbox_service.dart';

abstract interface class SingboxService {
  factory SingboxService() {
    if (Platform.isAndroid) {
      return MobileSingboxService();
    } else if (Platform.isIOS) {
      return MobileSingboxService();
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return FFISingboxService();
    } else {
      // OHOS adapt: HarmonyOS 走 FFI 直调 libcore.so（dart:ffi）
      // Dart 3.6 无 Platform.isOHOS，用兜底分支覆盖鸿蒙
      return FFISingboxService();
    }
  }

  Future<void> init();

  TaskEither<String, Unit> setup(
    String baseDir,
    String workingDir,
    String tempDir,
  );

  TaskEither<String, Unit> parseConfig(
    String path,
    String tempPath,
    bool debug,
  );

  TaskEither<String, Unit> changeConfigOptions(ConfigOptions options);

  TaskEither<String, Unit> start(String configPath);

  TaskEither<String, Unit> stop();

  TaskEither<String, Unit> restart(String configPath);

  Stream<String> watchOutbounds();

  TaskEither<String, Unit> selectOutbound(String groupTag, String outboundTag);

  TaskEither<String, Unit> urlTest(String groupTag);

  Stream<ConnectionStatus> watchConnectionStatus();

  Stream<String> watchStats();

  Stream<String> watchLogs(String path);
}
