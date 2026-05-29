import '../../data/chat_repository.dart';
import '../../models/chat_message.dart';
import 'chat_context_estimator.dart';

/// Compacts older turns into a single assistant summary row.
final class ChatCompressor {
  ChatCompressor({required this.repository});

  final ChatRepository repository;

  static const summaryPrefix = '[Compressed earlier conversation]\n';

  /// Returns number of messages removed (replaced by one summary).
  Future<int> compressSession(
    String sessionId, {
    int keepRecent = 8,
  }) async {
    final messages = await repository.getMessages(sessionId);
    if (messages.length <= keepRecent) return 0;

    final old = messages.sublist(0, messages.length - keepRecent);
    final keep = messages.sublist(messages.length - keepRecent);

    final summary = old.map(ChatContextEstimator.summarizeLine).join('\n');
    final body = '$summaryPrefix$summary';

    await repository.deleteMessagesByIds(old.map((m) => m.id).toList());
    await repository.insertMessage(
      sessionId: sessionId,
      role: ChatMessageRole.assistant,
      content: body,
      createdAt: keep.first.createdAt.subtract(const Duration(seconds: 1)),
    );

    return old.length;
  }
}
