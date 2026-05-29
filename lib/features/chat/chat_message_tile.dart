import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../theme/linkvault_design.dart';
import 'widgets/chat_ai_glow.dart';
import 'widgets/chat_thinking_tile.dart';
import 'widgets/chat_tool_call_tile.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    super.key,
    required this.message,
    this.pulsing = false,
    this.toolLabel,
    this.toolRunning = false,
    this.thinkingExpanded = true,
    this.onThinkingToggle,
  });

  final ChatMessageModel message;
  final bool pulsing;
  final String? toolLabel;
  final bool toolRunning;
  final bool thinkingExpanded;
  final VoidCallback? onThinkingToggle;

  @override
  Widget build(BuildContext context) {
    if (message.isThinking) {
      return ChatThinkingTile(
        text: message.content,
        expanded: thinkingExpanded,
        streaming: pulsing,
        onToggle: onThinkingToggle ?? () {},
      );
    }

    if (message.isTool) {
      return ChatToolCallTile(
        toolName: message.toolName ?? 'tool',
        label: toolLabel ?? message.toolName ?? 'Tool',
        content: message.content,
        running: toolRunning,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final phase = ChatAiGlowScope.phaseOf(context);
    final isUser = message.isUser;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.content.isEmpty && pulsing ? '…' : message.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          height: 1.35,
        ),
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(
          vertical: LinkvaultDesign.spaceXs,
          horizontal: LinkvaultDesign.spaceLg,
        ),
        child: isUser
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: LinkvaultDesign.radiusCard,
                  color: scheme.onSurface.withValues(alpha: 0.08),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: content,
              )
            : ChatAiGlowFrame(
                phase: phase,
                pulsing: pulsing,
                intensity: pulsing ? 1.15 : 0.95,
                child: content,
              ),
      ),
    );
  }
}
