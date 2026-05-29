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

// --- On-device LLM (Kotlin LiteRT-LM / MediaPipe, no flutter_gemma) ---

enum LlmBackend {
  cpu,
  gpu,
}

enum LlmHistoryRole {
  user,
  assistant,
  tool,
}

class LlmHistoryMessage {
  LlmHistoryMessage({
    required this.role,
    required this.content,
    this.toolName,
  });

  final LlmHistoryRole role;
  final String content;
  final String? toolName;
}

/// Sampling and context limits (applied when loading or updating session).
class LlmGenerationConfig {
  LlmGenerationConfig({
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.maxOutputTokens,
    required this.contextTokenLimit,
  });

  final double temperature;
  final int topK;
  final double topP;
  final int maxOutputTokens;
  final int contextTokenLimit;
}

/// Estimated context fill for the active native session.
class LlmContextStats {
  LlmContextStats({
    required this.usedTokens,
    required this.maxTokens,
  });

  final int usedTokens;
  final int maxTokens;
}

/// Native Gemma inference (download, load, stream) on Android.
@HostApi()
abstract class LlmHostApi {
  bool isModelInstalled(String fileName);

  /// Downloads to app files dir. Progress via [FlutterLlmApi.onDownloadProgress].
  void startModelDownload(String url, String fileName, String? bearerToken);

  void cancelModelDownload();

  void uninstallModel(String fileName);

  /// Loads weights and prepares a session. Heavy; call off UI thread (native does).
  @async
  void loadModel(String fileName, LlmBackend backend, int maxTokens);

  void unloadModel();

  void resetConversation();

  /// Replays Drift history into the native session (no generation).
  void replayHistory(List<LlmHistoryMessage> messages);

  /// Queues the user turn (call [startGeneration] after).
  void sendUserMessage(String text);

  /// After a tool call, send result and call [startGeneration] again.
  void sendToolResult(String toolName, String resultJson);

  /// Streams tokens via [FlutterLlmApi.onToken] until done or tool call.
  void startGeneration();

  void stopGeneration();

  /// `Using GPU`, `Using CPU`, or null if unloaded.
  String? getActiveBackendLabel();

  /// Updates sampler settings; recreates the native session with the same history.
  void applyGenerationConfig(LlmGenerationConfig config);

  /// Rough token estimate for the loaded session (history + pending).
  LlmContextStats getContextStats();
}

/// Streaming and download events from Kotlin to Dart.
@FlutterApi()
abstract class FlutterLlmApi {
  void onDownloadProgress(int percent);

  void onToken(String token);

  void onGenerationComplete(String fullText);

  void onFunctionCall(String name, String argsJson);

  void onLlmError(String code, String message);
}
