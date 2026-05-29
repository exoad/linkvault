import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../theme/linkvault_typography.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (message.role == ChatMessageRole.tool) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Text(
            '⚙ ${message.toolName ?? 'tool'}: ${message.content}',
            style: LinkvaultTypography.meta(scheme).copyWith(
              fontFamily: 'monospace',
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
    }

    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primary.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
