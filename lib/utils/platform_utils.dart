import 'dart:io';

abstract class PlatformUtils {
  static bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  /// Whether the app runs on HarmonyOS / OpenHarmony.
  ///
  /// The OHOS Flutter fork reports `operatingSystem == 'ohos'` and leaves
  /// [Platform.isLinux] false, so this has to be checked separately.
  static bool get isOhos => Platform.operatingSystem == 'ohos';
}
