import 'dart:convert';
import 'dart:io';

import 'package:package_config/package_config.dart';

void main() {
  final file = File(
    r'G:/DevTemp/workbuddyDL/hiddify-next-ohos/.dart_tool/package_config.json',
  );
  final pc = PackageConfig.parseBytes(
    utf8.encode(file.readAsStringSync()),
    file.uri,
  );
  for (final p in pc.packages) {
    if (p.name == 'hiddify') {
      print('name=${p.name}');
      print('root=${p.root}');
      print('packageUriRoot=${p.packageUriRoot}');
    }
  }
  final f = Uri.file(
    r'G:/DevTemp/workbuddyDL/hiddify-next-ohos/lib/main_dev.dart',
  );
  print('toPackageUri(main_dev.dart) = ${pc.toPackageUri(f)}');
}
