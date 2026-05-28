import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/linkvault_accent.dart';
import '../theme/linkvault_gradients.dart';

/// Slowly shifting edge vignettes and drifting color orbs behind content.
class LinkvaultAnimatedAmbient extends StatefulWidget {
  const LinkvaultAnimatedAmbient({
    super.key,
    this.intensity = 1.0,
    this.phase,
  });

  final double intensity;

  /// When set, uses this animation instead of an internal controller.
  final Animation<double>? phase;

  @override
  State<LinkvaultAnimatedAmbient> createState() =>
      _LinkvaultAnimatedAmbientState();
}

class _LinkvaultAnimatedAmbientState extends State<LinkvaultAnimatedAmbient>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  Animation<double> get _listenAnimation =>
      widget.phase ?? _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.phase != null) return;
    _syncController();
  }

  @override
  void didUpdateWidget(covariant LinkvaultAnimatedAmbient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phase != null) {
      _controller?.dispose();
      _controller = null;
    } else if (oldWidget.phase != null) {
      _syncController();
    }
  }

  void _syncController() {
    final shouldAnimate = LinkvaultGradients.enabled(context);
    if (!shouldAnimate) {
      _controller?.stop();
      return;
    }

    _controller ??= AnimationController(
      vsync: this,
      duration: AppMotion.ambientCycle,
    )..repeat();

    if (!_controller!.isAnimating) {
      _controller!.repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!LinkvaultGradients.enabled(context)) {
      return const SizedBox.shrink();
    }

    final accent = Theme.of(context).extension<LinkvaultAccent>();
    if (accent == null) return const SizedBox.shrink();

    if (widget.phase == null && _controller == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listenable = _listenAnimation;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          return CustomPaint(
            painter: _AmbientGlowPainter(
              accent: accent,
              t: listenable.value,
              intensity: widget.intensity,
              isDark: isDark,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({
    required this.accent,
    required this.t,
    required this.intensity,
    required this.isDark,
  });

  final LinkvaultAccent accent;
  final double t;
  final double intensity;
  final bool isDark;

  static const _orbConfigs = <_OrbConfig>[
    _OrbConfig(
      anchorX: 0.88,
      anchorY: 0.06,
      radius: 320,
      phaseOffset: 0.0,
      alphaScale: 1.0,
    ),
    _OrbConfig(
      anchorX: 0.10,
      anchorY: 0.14,
      radius: 280,
      phaseOffset: 0.31,
      alphaScale: 0.85,
    ),
    _OrbConfig(
      anchorX: 0.86,
      anchorY: 0.90,
      radius: 260,
      phaseOffset: 0.62,
      alphaScale: 0.75,
    ),
    _OrbConfig(
      anchorX: 0.14,
      anchorY: 0.92,
      radius: 220,
      phaseOffset: 0.48,
      alphaScale: 0.7,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final primaryAlpha = (isDark ? 0.22 : 0.18) * intensity;
    final tertiaryAlpha = (isDark ? 0.16 : 0.14) * intensity;
    final secondaryAlpha = (isDark ? 0.12 : 0.10) * intensity;
    final edgeAlpha = (isDark ? 0.28 : 0.22) * intensity;
    final fadeBase = isDark ? 0.45 : 0.38;

    final pulse = 0.88 + 0.12 * _wave(t);

    _paintEdgeVignette(
      canvas,
      size,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      color: _cycleColor(0.0),
      alpha: edgeAlpha * pulse,
      fade: fadeBase + 0.05 * _wave(t + 0.18),
    );
    _paintEdgeVignette(
      canvas,
      size,
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      color: _cycleColor(0.33),
      alpha: edgeAlpha * 0.9 * (1.04 - 0.08 * _wave(t + 0.42)),
      fade: fadeBase + 0.04 * _wave(t + 0.55),
    );
    _paintEdgeVignette(
      canvas,
      size,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      color: _cycleColor(0.66),
      alpha: edgeAlpha * 0.75 * (0.96 + 0.08 * _wave(t + 0.71)),
      fade: 0.5 + 0.06 * _wave(t + 0.12),
    );

    final alphas = [primaryAlpha, tertiaryAlpha, secondaryAlpha, tertiaryAlpha];
    for (var i = 0; i < _orbConfigs.length; i++) {
      final config = _orbConfigs[i];
      _paintOrb(
        canvas,
        size,
        config: config,
        color: _cycleColor(config.phaseOffset + t * 0.35),
        alpha: alphas[i] * config.alphaScale,
      );
    }
  }

  void _paintEdgeVignette(
    Canvas canvas,
    Size size, {
    required Alignment begin,
    required Alignment end,
    required Color color,
    required double alpha,
    required double fade,
  }) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          color.withValues(alpha: 0),
        ],
        stops: [0, fade.clamp(0.2, 0.65)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintOrb(
    Canvas canvas,
    Size size, {
    required _OrbConfig config,
    required Color color,
    required double alpha,
  }) {
    final drift = 42.0 * intensity;
    final phase = t + config.phaseOffset;
    final center = Offset(
      size.width * config.anchorX + drift * _wave(phase),
      size.height * config.anchorY + drift * _wave(phase + 0.27, freq: 0.85),
    );
    final radius =
        config.radius * (1.0 + 0.07 * _wave(phase + 0.5, freq: 0.45));
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  Color _cycleColor(double phase) {
    final colors = [accent.primary, accent.secondary, accent.tertiary];
    final p = (phase % 1.0) * colors.length;
    final index = p.floor() % colors.length;
    final next = (index + 1) % colors.length;
    return Color.lerp(colors[index], colors[next], p - p.floor())!;
  }

  double _wave(double phase, {double freq = 1.0}) =>
      math.sin((phase * freq) * math.pi * 2);

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.accent != accent ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isDark != isDark;
  }
}

class _OrbConfig {
  const _OrbConfig({
    required this.anchorX,
    required this.anchorY,
    required this.radius,
    required this.phaseOffset,
    required this.alphaScale,
  });

  final double anchorX;
  final double anchorY;
  final double radius;
  final double phaseOffset;
  final double alphaScale;
}

/// Exposes ambient motion phase to descendants (e.g. FAB glow).
class AmbientMotionScope extends InheritedWidget {
  const AmbientMotionScope({
    super.key,
    required this.phase,
    required super.child,
  });

  final Animation<double> phase;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AmbientMotionScope>()
        ?.phase;
  }

  @override
  bool updateShouldNotify(AmbientMotionScope oldWidget) =>
      oldWidget.phase != phase;
}

/// Soft pulsing glow under the paste FAB, synced to ambient motion when present.
class AmbientAwareFabGlow extends StatelessWidget {
  const AmbientAwareFabGlow({
    super.key,
    required this.child,
    required this.accent,
  });

  final Widget child;
  final LinkvaultAccent accent;

  @override
  Widget build(BuildContext context) {
    final phase = AmbientMotionScope.maybeOf(context);

    if (phase == null || !LinkvaultGradients.enabled(context)) {
      return _FabGlowStack(accent: accent, pulse: 1.0, child: child);
    }

    return AnimatedBuilder(
      animation: phase,
      builder: (context, child) {
        final pulse = 0.82 + 0.18 * math.sin(phase.value * math.pi * 2);
        return _FabGlowStack(
          accent: accent,
          pulse: pulse,
          child: child!,
        );
      },
      child: child,
    );
  }
}

class _FabGlowStack extends StatelessWidget {
  const _FabGlowStack({
    required this.accent,
    required this.pulse,
    required this.child,
  });

  final LinkvaultAccent accent;
  final double pulse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = accent.primary;
    final tertiary = accent.tertiary;
    final t = ((pulse - 0.82) / 0.18).clamp(0.0, 1.0);
    final secondaryMix =
        Color.lerp(primary, accent.secondary, t)!;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          child: Container(
            width: 200,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: secondaryMix.withValues(alpha: 0.22 + 0.18 * pulse),
                  blurRadius: lerpDouble(22, 32, t)!,
                  spreadRadius: lerpDouble(0, 3, t)!,
                ),
                BoxShadow(
                  color: tertiary.withValues(alpha: 0.10 + 0.12 * pulse),
                  blurRadius: lerpDouble(32, 48, t)!,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
