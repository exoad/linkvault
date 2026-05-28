import 'dart:io';

import 'package:flutter/services.dart';

/// Android APK install permission and package installer intents.
class ApkInstaller {
  static const _channel = MethodChannel('net.exoad.linkvault/install');

  /// Whether the user has allowed this app to install packages (Android 8+).
  static Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return false;
    final allowed = await _channel.invokeMethod<bool>('canInstallPackages');
    return allowed ?? false;
  }

  /// Opens the system screen: Allow from this source / Install unknown apps.
  static Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openInstallPermissionSettings');
  }

  /// Triggers the system package installer for a downloaded APK.
  static Future<void> install(File apkFile) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK install is Android-only');
    }
    await _channel.invokeMethod<void>('installApk', {
      'path': apkFile.path,
    });
  }
}
