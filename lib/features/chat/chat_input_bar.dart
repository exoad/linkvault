import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'widgets/chat_ai_glow.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onStop,
    required this.isGenerating,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isGenerating;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase);
    final pulse = isGenerating
        ? 0.7 + 0.3 * math.sin(phase * math.pi * 4)
        : 0.85;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface.withValues(alpha: 0),
              scheme.surface.withValues(alpha: 0.75),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 8 + bottom),
          child: ChatAiGlowFrame(
            phase: phase,
            pulsing: isGenerating,
            intensity: isGenerating ? 1.2 : 0.7,
            borderRadius: 24,
            borderWidth: isGenerating ? 2 : 1.2,
            fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.88),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: enabled && !isGenerating,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: isGenerating ? 'Thinking…' : 'Message…',
                        hintStyle: TextStyle(
                          color: glow.primary.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: scheme.surface.withValues(alpha: 0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SendOrb(
                    glow: glow,
                    pulse: pulse,
                    isGenerating: isGenerating,
                    onPressed: isGenerating
                        ? onStop
                        : (enabled && controller.text.trim().isNotEmpty
                            ? onSend
                            : null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendOrb extends StatelessWidget {
  const _SendOrb({
    required this.glow,
    required this.pulse,
    required this.isGenerating,
    required this.onPressed,
  });

  final ChatAiGlowColors glow;
  final double pulse;
  final bool isGenerating;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow.bubbleShadows(intensity: isGenerating ? 1.3 : 0.6, pulse: pulse),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glow.primary.withValues(alpha: 0.85),
            glow.secondary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: PhosphorIcon(
          isGenerating ? PhosphorIcons.stop : PhosphorIcons.paperPlaneRight,
          color: scheme.surface,
        ),
      ),
    );
  }
}
