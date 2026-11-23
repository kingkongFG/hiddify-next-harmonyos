// OHOS adapt: `flutter create` generated this file as the default Flutter
// template (a counter demo) and it is not tracked by upstream hiddify-next.
//
// Upstream does not use lib/main.dart at all: its Makefile builds with
// TARGET=lib/main_$(FLAVOR).dart, where FLAVOR is "dev" for debug builds and
// "prod" for release builds, so lib/main_dev.dart and lib/main_prod.dart are
// the real entry points.
//
// The HarmonyOS hvigor build drives "flutter assemble" through
// flutter-hvigor-plugin, which defaults to -dTargetFile=lib/main.dart. That
// compact -d form cannot carry a value containing a dot (args splits
// "lib/main_dev.dart" into "lib/main_dev" plus ".dart"), so pointing the
// plugin at lib/main_dev.dart is not reliable.
//
// Keeping lib/main.dart as the entry point and making it mirror the upstream
// dev entry point keeps the default build path working. The release build
// still selects lib/main_prod.dart through the FLUTTER_TARGET build parameter.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/domain/environment.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // OHOS adapt: release builds drop framework/platform errors on the floor,
  // so a widget that throws during build looks exactly like a black window.
  // Mirroring every error into hilog (Flutter forwards stdout there) is the
  // only way to see them through `hdc shell hilog`.
  FlutterError.onError = (FlutterErrorDetails details) {
    print('[DIAG] FLUTTER ERROR: ${details.exceptionAsString()}');
    print('[DIAG] FLUTTER STACK: ${details.stack}');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    print('[DIAG] PLATFORM ERROR: $error');
    print('[DIAG] PLATFORM STACK: $stack');
    return true;
  };

  return lazyBootstrap(widgetsBinding, Environment.dev);
}
