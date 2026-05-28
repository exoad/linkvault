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
    this.intensity = LinkvaultGradients.ambientIntensity,
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

  /// Mesh of soft glow blobs (anchors as fractions of the canvas).
  static const _blobs = <_BlobConfig>[
    _BlobConfig(
      anchorX: 0.80,
      anchorY: 0.00,
      radiusScale: 0.62,
      phaseOffset: 0.0,
      alphaScale: 1.0,
    ),
    _BlobConfig(
      anchorX: 0.02,
      anchorY: 0.26,
      radiusScale: 0.56,
      phaseOffset: 0.33,
      alphaScale: 0.92,
    ),
    _BlobConfig(
      anchorX: 0.95,
      anchorY: 0.80,
      radiusScale: 0.58,
      phaseOffset: 0.66,
      alphaScale: 0.95,
    ),
    _BlobConfig(
      anchorX: 0.30,
      anchorY: 1.02,
      radiusScale: 0.52,
      phaseOffset: 0.16,
      alphaScale: 0.85,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shortest = size.shortestSide;
    final drift = shortest * 0.11 * intensity;

    // Additive blending on the dark canvas creates the bright, blended
    // overlaps characteristic of modern "tech" aurora glows. Light themes
    // blend normally so the washes stay soft pastels instead of blowing out.
    final blend = isDark ? BlendMode.plus : BlendMode.srcOver;
    final baseAlpha = (isDark ? 0.46 : 0.24) * intensity;

    canvas.saveLayer(rect, Paint());
    for (final blob in _blobs) {
      final phase = t + blob.phaseOffset;
      final center = Offset(
        size.width * blob.anchorX + drift * _wave(phase),
        size.height * blob.anchorY + drift * _wave(phase + 0.27, freq: 0.85),
      );
      final radius = shortest *
          blob.radiusScale *
          (1.0 + 0.10 * _wave(phase + 0.5, freq: 0.5));
      final color = _cycleColor(blob.phaseOffset + t);
      final alpha = (baseAlpha * blob.alphaScale).clamp(0.0, 1.0);

      final paint = Paint()
        ..blendMode = blend
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.45),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    canvas.restore();
  }

  Color _cycleColor(double phase) => accent.cycleColor(phase);

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

class _BlobConfig {
  const _BlobConfig({
    required this.anchorX,
    required this.anchorY,
    required this.radiusScale,
    required this.phaseOffset,
    required this.alphaScale,
  });

  /// Anchor as a fraction of canvas width/height.
  final double anchorX;
  final double anchorY;

  /// Blob radius as a fraction of the canvas shortest side.
  final double radiusScale;
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
        final pulse = 0.7 + 0.3 * math.sin(phase.value * math.pi * 2);
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
    final t = ((pulse - 0.4) / 0.6).clamp(0.0, 1.0);
    // Drift the glow hue with the pulse so it feels alive, not static.
    final warm = Color.lerp(accent.primary, accent.secondary, t)!;
    final cool = Color.lerp(accent.tertiary, accent.primary, t)!;

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
                  color: warm.withValues(alpha: 0.10 + 0.12 * pulse),
                  blurRadius: lerpDouble(18, 30, t)!,
                  spreadRadius: lerpDouble(0, 2, t)!,
                ),
                BoxShadow(
                  color: cool.withValues(alpha: 0.06 + 0.08 * pulse),
                  blurRadius: lerpDouble(28, 42, t)!,
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
