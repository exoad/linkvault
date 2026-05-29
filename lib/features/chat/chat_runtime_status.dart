import '../../ai/chat/chat_service.dart' show ChatPrepareStep;
import 'chat_streaming_draft.dart';

/// User-visible inference / load state for the chat status strip.
enum ChatRuntimeStatus {
  checkingInstall,
  downloading,
  loadingModel,
  preparingSession,
  ready,
  notLoaded,
  sending,
  waitingForReply,
  thinking,
  writing,
  runningTool,
  error,
}

/// Maps screen state to [ChatRuntimeStatus] and display copy.
final class ChatRuntimeStatusMapper {
  const ChatRuntimeStatusMapper._();

  static ChatRuntimeStatus resolve({
    required ChatUiPhase phase,
    required bool modelLoaded,
    required bool isGenerating,
    required ChatStreamingDraft? draft,
    required ChatPrepareStep? prepareStep,
    required int downloadProgress,
    required String backendLabel,
    required String? errorMessage,
    required bool streamReceivedEvent,
  }) {
  switch (phase) {
    case ChatUiPhase.checking:
      return ChatRuntimeStatus.checkingInstall;
    case ChatUiPhase.downloading:
      return ChatRuntimeStatus.downloading;
    case ChatUiPhase.loading:
      if (prepareStep == ChatPrepareStep.replayingHistory) {
        return ChatRuntimeStatus.preparingSession;
      }
      return ChatRuntimeStatus.loadingModel;
    case ChatUiPhase.needsDownload:
      return ChatRuntimeStatus.checkingInstall;
    case ChatUiPhase.error:
      return ChatRuntimeStatus.error;
    case ChatUiPhase.ready:
      if (!modelLoaded) {
        return ChatRuntimeStatus.notLoaded;
      }
      if (errorMessage != null && errorMessage.isNotEmpty && !isGenerating) {
        return ChatRuntimeStatus.error;
      }
      if (!isGenerating || draft == null) {
        return ChatRuntimeStatus.ready;
      }
      for (final tool in draft.tools) {
        if (tool.running) {
          return ChatRuntimeStatus.runningTool;
        }
      }
      if (draft.thinkingText.isNotEmpty) {
        return ChatRuntimeStatus.thinking;
      }
      if (draft.assistantText.isNotEmpty) {
        return ChatRuntimeStatus.writing;
      }
      if (draft.tools.isNotEmpty) {
        return ChatRuntimeStatus.runningTool;
      }
      if (streamReceivedEvent) {
        return ChatRuntimeStatus.waitingForReply;
      }
      return ChatRuntimeStatus.sending;
  }
  }

  static String label(
    ChatRuntimeStatus status, {
    required int downloadProgress,
    required String backendLabel,
    required String? errorMessage,
    String? toolLabel,
  }) {
    return switch (status) {
      ChatRuntimeStatus.checkingInstall =>
        'Checking for on-device model…',
      ChatRuntimeStatus.downloading =>
        'Downloading model… $downloadProgress%',
      ChatRuntimeStatus.loadingModel =>
        'Loading Gemma into memory…',
      ChatRuntimeStatus.preparingSession =>
        'Restoring conversation…',
      ChatRuntimeStatus.ready => backendLabel.isNotEmpty
          ? 'Ready · $backendLabel'
          : 'Ready',
      ChatRuntimeStatus.notLoaded =>
        'Model not loaded — tap to retry',
      ChatRuntimeStatus.sending => 'Sending…',
      ChatRuntimeStatus.waitingForReply =>
        'Waiting for response…',
      ChatRuntimeStatus.thinking => 'Thinking…',
      ChatRuntimeStatus.writing => 'Writing…',
      ChatRuntimeStatus.runningTool => toolLabel != null
          ? 'Running $toolLabel…'
          : 'Running tool…',
      ChatRuntimeStatus.error => errorMessage != null &&
              errorMessage.isNotEmpty
          ? '$errorMessage · Tap to retry'
          : 'Something went wrong · Tap to retry',
    };
  }

  static bool showsSpinner(ChatRuntimeStatus status) {
    return switch (status) {
      ChatRuntimeStatus.checkingInstall ||
      ChatRuntimeStatus.downloading ||
      ChatRuntimeStatus.loadingModel ||
      ChatRuntimeStatus.preparingSession ||
      ChatRuntimeStatus.sending ||
      ChatRuntimeStatus.waitingForReply ||
      ChatRuntimeStatus.thinking ||
      ChatRuntimeStatus.writing ||
      ChatRuntimeStatus.runningTool =>
        true,
      ChatRuntimeStatus.ready ||
      ChatRuntimeStatus.notLoaded ||
      ChatRuntimeStatus.error =>
        false,
    };
  }

  static bool isRetryable(ChatRuntimeStatus status) {
    return status == ChatRuntimeStatus.notLoaded ||
        status == ChatRuntimeStatus.error;
  }
}

/// Mirrors private [_ChatUiPhase] for status mapping.
enum ChatUiPhase {
  checking,
  needsDownload,
  downloading,
  loading,
  ready,
  error,
}
