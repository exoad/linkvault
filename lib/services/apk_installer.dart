import 'dart:io';

import 'package:flutter/services.dart';

/// Result of comparing the installed app certificate to a downloaded APK.
class ApkSigningCheck {
  const ApkSigningCheck({
    required this.compatible,
    this.installedCertSha256,
    this.apkCertSha256,
  });

  final bool compatible;
  final String? installedCertSha256;
  final String? apkCertSha256;

  factory ApkSigningCheck.fromMap(Map<dynamic, dynamic> map) {
    return ApkSigningCheck(
      compatible: map['compatible'] as bool? ?? false,
      installedCertSha256: map['installedCertSha256'] as String?,
      apkCertSha256: map['apkCertSha256'] as String?,
    );
  }

  bool get isSigningMismatch => !compatible;
}

/// Android APK install permission and package installer intents.
class ApkInstaller {
  static const _channel = MethodChannel('net.exoad.linkvault/install');

  static const signingMismatchCode = 'SIGNING_MISMATCH';

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

  /// Compares signing certificates before install.
  static Future<ApkSigningCheck> checkApkSigning(File apkFile) async {
    if (!Platform.isAndroid) {
      return const ApkSigningCheck(compatible: true);
    }
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'checkApkSigning',
      {'path': apkFile.path},
    );
    return ApkSigningCheck.fromMap(result ?? {});
  }

  /// Triggers the system package installer for a downloaded APK.
  static Future<void> install(File apkFile) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK install is Android-only');
    }
    try {
      await _channel.invokeMethod<void>('installApk', {
        'path': apkFile.path,
      });
    } on PlatformException catch (e) {
      if (e.message?.contains(signingMismatchCode) == true ||
          e.message?.contains('signed with a different key') == true) {
        throw ApkSigningMismatchException();
      }
      rethrow;
    }
  }
}

/// Thrown when the update APK is not signed with the same key as the installed app.
class ApkSigningMismatchException implements Exception {
  @override
  String toString() =>
      'Update APK signing does not match the installed app.';
}
