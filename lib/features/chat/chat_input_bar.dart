import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../theme/app_motion.dart';
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
          child: _InputShell(
            scheme: scheme,
            phase: phase,
            isGenerating: isGenerating,
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
                          color: isGenerating
                              ? glow.primary.withValues(alpha: 0.45)
                              : scheme.onSurface.withValues(alpha: 0.4),
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

class _InputShell extends StatelessWidget {
  const _InputShell({
    required this.scheme,
    required this.phase,
    required this.isGenerating,
    required this.child,
  });

  final ColorScheme scheme;
  final double phase;
  final bool isGenerating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return ChatAiGlowFrame(
        phase: phase,
        pulsing: true,
        intensity: 1.2,
        borderRadius: 24,
        borderWidth: 2,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.88),
        child: child,
      );
    }

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.88),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: child,
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
        boxShadow: isGenerating
            ? glow.bubbleShadows(intensity: 1.3, pulse: pulse)
            : null,
        color: isGenerating ? null : scheme.surfaceContainerHigh,
        gradient: isGenerating
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glow.primary.withValues(alpha: 0.85),
                  glow.secondary.withValues(alpha: 0.75),
                ],
              )
            : null,
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
