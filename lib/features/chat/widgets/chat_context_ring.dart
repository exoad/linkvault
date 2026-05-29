import 'package:flutter/material.dart';

import '../../../theme/linkvault_typography.dart';
import 'chat_ai_glow.dart';

/// Circular indicator for estimated context usage (used / limit tokens).
class ChatContextRing extends StatelessWidget {
  const ChatContextRing({
    super.key,
    required this.usedTokens,
    required this.maxTokens,
    this.onTap,
  });

  final int usedTokens;
  final int maxTokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = ChatAiGlowScope.phaseOf(context);
    final glow = ChatAiGlowColors.at(phase);
    final ratio = maxTokens > 0 ? (usedTokens / maxTokens).clamp(0.0, 1.0) : 0.0;
    final label = _compactLabel(usedTokens, maxTokens);
    final color = ratio > 0.9
        ? scheme.error
        : ratio > 0.75
            ? glow.secondary
            : glow.primary;

    return Semantics(
      label: 'Context $label tokens used',
      button: onTap != null,
      child: Tooltip(
        message: 'Context: $usedTokens / $maxTokens tokens',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio > 0 ? ratio : null,
                  strokeWidth: 3,
                  backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                  color: color,
                ),
                Text(
                  label,
                  style: LinkvaultTypography.meta(scheme).copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _compactLabel(int used, int max) {
    String fmt(int n) {
      if (n >= 10000) return '${(n / 1000).round()}k';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
      return '$n';
    }
    return fmt(used);
  }
}
