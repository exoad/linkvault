import 'package:pigeon/pigeon.dart';

// Type-safe Dart <-> Kotlin platform contract for Linkvault.
//
// Regenerate after editing:
//   dart run pigeon --input pigeons/app_api.dart
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/app_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/net/exoad/linkvault/AppApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'net.exoad.linkvault'),
    dartPackageName: 'linkvault',
  ),
)

/// What an external Android intent wants the hub to do.
enum IntentKind {
  /// A URL was shared/selected — save it as a link.
  saveLink,

  /// Start a new note (empty or seeded with [IncomingIntent.text]).
  newNote,

  /// Generic shared text with no obvious URL — let a module decide.
  shareText,
}

/// A normalized external intent delivered from Kotlin to Flutter.
class IncomingIntent {
  IncomingIntent({
    required this.kind,
    this.text,
    this.targetModuleId,
  });

  final IntentKind kind;

  /// Shared/selected text or URL, if any.
  final String? text;

  /// Optional hub module id hint (e.g. from a launcher shortcut).
  final String? targetModuleId;
}

/// Result of comparing the installed app signature to a downloaded APK.
class ApkSigningResult {
  ApkSigningResult({
    required this.compatible,
    this.installedCertSha256,
    this.apkCertSha256,
  });

  final bool compatible;
  final String? installedCertSha256;
  final String? apkCertSha256;
}

/// Android package-install + signing operations (implemented in Kotlin).
@HostApi()
abstract class InstallHostApi {
  /// Whether the user allows this app to install packages (Android 8+).
  bool canInstallPackages();

  /// Opens the system "install unknown apps" settings screen for this app.
  void openInstallPermissionSettings();

  /// Compares the installed app certificate with the APK at [path].
  ApkSigningResult checkApkSigning(String path);

  /// Launches the system package installer for the APK at [path].
  ///
  /// Throws a `SIGNING_MISMATCH` coded error if the APK was signed with a
  /// different key than the installed app.
  void installApk(String path);
}

/// Native shell hooks (splash handoff, window polish).
@HostApi()
abstract class UiHostApi {
  /// Called after the first Flutter frame so Android can dismiss the splash.
  void notifyUiReady();
}

/// External intent entry point that Flutter pulls from on startup (Kotlin).
@HostApi()
abstract class IntentHostApi {
  /// Returns the intent that launched the app (share/shortcut), if any.
  ///
  /// Consumed once: a second call returns null. Avoids the cold-start race
  /// where the host could fire before Flutter registers [FlutterIntentApi].
  IncomingIntent? getInitialIntent();
}

/// External intents pushed from Kotlin into Flutter while running (warm start).
@FlutterApi()
abstract class FlutterIntentApi {
  void onIntent(IncomingIntent intent);
}
