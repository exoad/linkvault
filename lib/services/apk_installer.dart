import 'dart:io';

import 'package:flutter/services.dart';

/// Triggers the system package installer for a downloaded APK.
class ApkInstaller {
  static const _channel = MethodChannel('net.exoad.linkvault/install');

  static Future<void> install(File apkFile) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK install is Android-only');
    }
    await _channel.invokeMethod<void>('installApk', {
      'path': apkFile.path,
    });
  }
}
