import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../ai/chat/tool_message_payload.dart';
import '../../../theme/linkvault_typography.dart';
import 'chat_ai_glow.dart';

class ChatToolCallTile extends StatelessWidget {
  const ChatToolCallTile({
    super.key,
    required this.toolName,
    required this.label,
    required this.content,
    this.running = false,
  });

  final String toolName;
  final String label;
  final String content;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase, pulse: running ? 1 : 0.8);
    final payload = ToolMessagePayload.parse(content);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        child: ChatAiGlowFrame(
          phase: phase,
          pulsing: running,
          intensity: running ? 0.85 : 0.65,
          borderRadius: 14,
          borderWidth: 1,
          fillColor: scheme.surface.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ToolIcon(name: toolName, color: glow.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: LinkvaultTypography.meta(scheme).copyWith(
                          fontWeight: FontWeight.w600,
                          color: glow.secondary.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    if (running)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: glow.primary,
                        ),
                      )
                    else
                      PhosphorIcon(
                        PhosphorIcons.checkCircle,
                        size: 16,
                        color: glow.primary.withValues(alpha: 0.85),
                      ),
                  ],
                ),
                if (payload.argsSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    payload.argsSummary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (payload.hasResult) ...[
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: scheme.onSurface.withValues(alpha: 0.05),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        payload.result!,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.35,
                          color: scheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (name) {
      'get_current_time' => PhosphorIcons.clock,
      'web_search' => PhosphorIcons.magnifyingGlass,
      'open_url' => PhosphorIcons.arrowSquareOut,
      _ => PhosphorIcons.wrench,
    };
    return PhosphorIcon(icon, size: 18, color: color);
  }
}
