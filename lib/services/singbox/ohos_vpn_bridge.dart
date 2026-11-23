import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';

final _logger = Loggy('OhosVpnBridge');

/// Bridge to the HarmonyOS system VPN Extension.
///
/// The extension always runs in its own process and owns the TUN device: the
/// system creates the virtual NIC and returns its file descriptor. That
/// descriptor travels back to the UI process over an RPC channel and is then
/// injected into the Go core through FFI, so the core can read/write the
/// tunnel directly.
class OhosVpnBridge {
  OhosVpnBridge._();

  static final OhosVpnBridge instance = OhosVpnBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.hiddify.app/ohos.vpn',
  );

  static const Duration _timeout = Duration(seconds: 30);

  /// Whether the HarmonyOS VPN bridge can be used on this platform.
  static bool get isSupported => Platform.operatingSystem == 'ohos';

  /// Starts the VPN Extension and returns the TUN file descriptor.
  Future<int> prepare() async {
    _logger.debug('starting the vpn extension');
    final int? fd;
    try {
      fd = await _channel.invokeMethod<int>('prepare').timeout(_timeout);
    } on TimeoutException catch (e) {
      _logger.error('the vpn extension timed out: $e');
      rethrow;
    }
    if (fd == null || fd <= 0) {
      throw StateError('the vpn extension returned an invalid tun fd: $fd');
    }
    _logger.debug('received tun fd: $fd');
    return fd;
  }

  /// Stops the VPN Extension.
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e) {
      _logger.error('failed to stop the vpn extension: $e');
    }
  }
}
