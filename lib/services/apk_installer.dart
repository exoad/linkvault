import 'dart:io';

import 'package:flutter/services.dart';

import '../platform/app_api.g.dart';

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

  factory ApkSigningCheck.fromResult(ApkSigningResult result) {
    return ApkSigningCheck(
      compatible: result.compatible,
      installedCertSha256: result.installedCertSha256,
      apkCertSha256: result.apkCertSha256,
    );
  }

  bool get isSigningMismatch => !compatible;
}

/// Android APK install permission and package installer intents.
///
/// Thin Dart facade over the Pigeon-generated [InstallHostApi]; the heavy
/// lifting lives in Kotlin (`InstallManager`).
class ApkInstaller {
  static final InstallHostApi _api = InstallHostApi();

  static const signingMismatchCode = 'SIGNING_MISMATCH';

  /// Whether the user has allowed this app to install packages (Android 8+).
  static Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return false;
    return _api.canInstallPackages();
  }

  /// Opens the system screen: Allow from this source / Install unknown apps.
  static Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    await _api.openInstallPermissionSettings();
  }

  /// Compares signing certificates before install.
  static Future<ApkSigningCheck> checkApkSigning(File apkFile) async {
    if (!Platform.isAndroid) {
      return const ApkSigningCheck(compatible: true);
    }
    final result = await _api.checkApkSigning(apkFile.path);
    return ApkSigningCheck.fromResult(result);
  }

  /// Triggers the system package installer for a downloaded APK.
  static Future<void> install(File apkFile) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK install is Android-only');
    }
    try {
      await _api.installApk(apkFile.path);
    } on PlatformException catch (e) {
      if (e.code == signingMismatchCode ||
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
