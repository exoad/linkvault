import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/linkvault_design.dart';
import '../../../theme/linkvault_typography.dart';
import 'chat_ai_glow.dart';

class ChatThinkingTile extends StatelessWidget {
  const ChatThinkingTile({
    super.key,
    required this.text,
    required this.expanded,
    required this.streaming,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final bool streaming;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase, pulse: streaming ? 1 : 0.85);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        margin: const EdgeInsets.symmetric(
          vertical: LinkvaultDesign.spaceSm,
          horizontal: LinkvaultDesign.spaceLg,
        ),
        child: ChatAiGlowFrame(
          phase: phase,
          pulsing: streaming,
          intensity: 0.55,
          borderRadius: LinkvaultDesign.radiusMd,
          borderWidth: 1,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.brain,
                        size: 16,
                        color: glow.primary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        streaming ? 'Thinking…' : 'Thought process',
                        style: LinkvaultTypography.meta(scheme).copyWith(
                          fontWeight: FontWeight.w600,
                          color: glow.secondary.withValues(alpha: 0.95),
                        ),
                      ),
                      const Spacer(),
                      PhosphorIcon(
                        expanded ? PhosphorIcons.caretUp : PhosphorIcons.caretDown,
                        size: 14,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded && text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
