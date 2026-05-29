import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../theme/ambient_lava_palette.dart';
import '../../../theme/linkvault_gradients.dart';

/// AI chat chroma sampled from the global ambient cycle.
class ChatAiGlowColors {
  const ChatAiGlowColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  static ChatAiGlowColors at(double phase, {double pulse = 1.0}) {
    final p = phase % 1.0;
    return ChatAiGlowColors(
      primary: AmbientLavaPalette.colorAt(p),
      secondary: AmbientLavaPalette.colorAt(p + 0.33),
      tertiary: AmbientLavaPalette.colorAt(p + 0.66),
    );
  }

  List<Color> get gradient => [primary, secondary, tertiary, primary];

  List<BoxShadow> bubbleShadows({double intensity = 1.0, double pulse = 1.0}) {
    final i = intensity.clamp(0.0, 1.5);
    final p = pulse.clamp(0.4, 1.2);
    return [
      BoxShadow(
        color: primary.withValues(alpha: 0.22 * i * p),
        blurRadius: lerpDouble(14, 26, p)!,
        spreadRadius: lerpDouble(0, 1.2, p)!,
      ),
      BoxShadow(
        color: secondary.withValues(alpha: 0.16 * i * p),
        blurRadius: lerpDouble(20, 34, p)!,
      ),
      BoxShadow(
        color: tertiary.withValues(alpha: 0.10 * i * p),
        blurRadius: lerpDouble(28, 44, p)!,
        spreadRadius: -2,
      ),
    ];
  }
}

/// Soft edge washes behind the chat transcript (AI “aurora” at screen edges).
class ChatAiEdgeAtmosphere extends StatelessWidget {
  const ChatAiEdgeAtmosphere({super.key, required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    if (!LinkvaultGradients.enabled(context)) {
      return const SizedBox.shrink();
    }

    final colors = ChatAiGlowColors.at(phase);
    final pulse = 0.75 + 0.25 * math.sin(phase * math.pi * 2);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -80,
            top: -40,
            child: _wash(
              220,
              colors.primary.withValues(alpha: 0.14 * pulse),
            ),
          ),
          Positioned(
            right: -60,
            top: 80,
            child: _wash(
              200,
              colors.secondary.withValues(alpha: 0.12 * pulse),
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: -20,
            child: _wash(
              180,
              colors.tertiary.withValues(alpha: 0.18 * pulse),
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wash(double height, Color color, {double? width}) {
    return Container(
      width: width ?? height,
      height: height,
      decoration: BoxDecoration(
        shape: width == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: width != null ? BorderRadius.circular(999) : null,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Gradient rim + glow for assistant / tool UI.
class ChatAiGlowFrame extends StatelessWidget {
  const ChatAiGlowFrame({
    super.key,
    required this.phase,
    required this.child,
    this.pulsing = false,
    this.intensity = 1.0,
    this.borderWidth = 1.5,
    this.borderRadius = 18,
    this.fillColor,
  });

  final double phase;
  final Widget child;
  final bool pulsing;
  final double intensity;
  final double borderWidth;
  final double borderRadius;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pulse = pulsing
        ? 0.72 + 0.28 * math.sin(phase * math.pi * 4)
        : 0.85;
    final colors = ChatAiGlowColors.at(phase, pulse: pulse);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: colors.bubbleShadows(intensity: intensity, pulse: pulse),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.gradient
                .map((c) => c.withValues(alpha: 0.55 + 0.35 * pulse))
                .toList(),
          ),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            color: fillColor ?? scheme.surfaceContainerHigh.withValues(alpha: 0.82),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Syncs ambient phase for chat descendants.
class ChatAiGlowScope extends StatelessWidget {
  const ChatAiGlowScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ambient = AmbientMotionScope.maybeOf(context);
    if (ambient == null) {
      return _ChatAiGlowInherited(phase: 0, child: child);
    }
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        return _ChatAiGlowInherited(
          phase: ambient.value,
          child: child!,
        );
      },
      child: child,
    );
  }

  static double phaseOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ChatAiGlowInherited>();
    return scope?.phase ?? 0;
  }
}

class _ChatAiGlowInherited extends InheritedWidget {
  const _ChatAiGlowInherited({required this.phase, required super.child});

  final double phase;

  @override
  bool updateShouldNotify(_ChatAiGlowInherited oldWidget) => phase != oldWidget.phase;
}
