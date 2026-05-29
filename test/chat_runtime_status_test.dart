import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/chat/chat_service.dart';
import 'package:linkvault/features/chat/chat_runtime_status.dart';
import 'package:linkvault/features/chat/chat_streaming_draft.dart';

void main() {
  test('label for ready includes backend', () {
    final label = ChatRuntimeStatusMapper.label(
      ChatRuntimeStatus.ready,
      downloadProgress: 0,
      backendLabel: 'Using GPU',
      errorMessage: null,
    );
    expect(label, contains('GPU'));
  });

  test('resolve sending when generating without stream events', () {
    final draft = ChatStreamingDraft(sessionId: 's');
    final status = ChatRuntimeStatusMapper.resolve(
      phase: ChatUiPhase.ready,
      modelLoaded: true,
      isGenerating: true,
      draft: draft,
      prepareStep: null,
      downloadProgress: 0,
      backendLabel: 'Using GPU',
      errorMessage: null,
      streamReceivedEvent: false,
    );
    expect(status, ChatRuntimeStatus.sending);
  });

  test('resolve preparingSession during replay step', () {
    final status = ChatRuntimeStatusMapper.resolve(
      phase: ChatUiPhase.loading,
      modelLoaded: false,
      isGenerating: false,
      draft: null,
      prepareStep: ChatPrepareStep.replayingHistory,
      downloadProgress: 0,
      backendLabel: '',
      errorMessage: null,
      streamReceivedEvent: false,
    );
    expect(status, ChatRuntimeStatus.preparingSession);
  });

  test('resolve notLoaded when ready without backend', () {
    final status = ChatRuntimeStatusMapper.resolve(
      phase: ChatUiPhase.ready,
      modelLoaded: false,
      isGenerating: false,
      draft: null,
      prepareStep: null,
      downloadProgress: 0,
      backendLabel: '',
      errorMessage: null,
      streamReceivedEvent: false,
    );
    expect(status, ChatRuntimeStatus.notLoaded);
  });
}
