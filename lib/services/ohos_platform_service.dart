import 'package:flutter/services.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';

/// HarmonyOS platform bridge for clipboard access and the system share sheet.
///
/// `share_plus` has no `ohos` implementation and the Flutter engine's
/// `Clipboard.getData` depends on `ohos.permission.READ_PASTEBOARD` being
/// declared and granted. This service talks to the ArkTS side directly and
/// always falls back to the Flutter channel so a missing native method never
/// leaves the user with a dead button.
class OhosPlatformService with InfraLogger {
  OhosPlatformService._();

  static final OhosPlatformService instance = OhosPlatformService._();

  static const MethodChannel _channel =
      MethodChannel('com.hiddify.app/ohos.platform');

  static bool get isSupported => PlatformUtils.isOhos;

  /// Reads the clipboard. Native pasteboard first, Flutter channel as backup.
  Future<String> readClipboard() async {
    if (isSupported) {
      try {
        final text = await _channel.invokeMethod<String>('readClipboard');
        if (text != null && text.trim().isNotEmpty) {
          loggy.debug('native clipboard read, ${text.length} chars');
          return text;
        }
      } catch (e) {
        loggy.warning('native clipboard read failed: $e');
      }
    }
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text ?? '';
    } catch (e) {
      loggy.warning('flutter clipboard read failed: $e');
      return '';
    }
  }

  /// Copies text to the clipboard, trying both native and Flutter channels.
  Future<bool> copyToClipboard(String text) async {
    var ok = false;
    if (isSupported) {
      try {
        ok = await _channel.invokeMethod<bool>('writeClipboard', {
              'text': text,
            }) ??
            false;
      } catch (e) {
        loggy.warning('native clipboard write failed: $e');
      }
    }
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      loggy.warning('flutter clipboard write failed: $e');
    }
    return ok;
  }

  /// Opens the system share sheet. Returns false when no share target exists;
  /// callers should fall back to copying the text.
  Future<bool> shareText(String text, {String? title}) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('shareText', {
            'text': text,
            'title': title ?? '',
          }) ??
          false;
    } catch (e) {
      loggy.warning('native share failed: $e');
      return false;
    }
  }
}
