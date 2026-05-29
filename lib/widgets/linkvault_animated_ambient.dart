import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/ambient_lava_palette.dart';
import '../theme/app_motion.dart';
import '../theme/linkvault_gradients.dart';

/// Lava-lamp ambient: multi-lobe blobs drift and auto-cycle through the palette.
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
            painter: _LavaAmbientPainter(
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

class _LavaAmbientPainter extends CustomPainter {
  _LavaAmbientPainter({
    required this.t,
    required this.intensity,
    required this.isDark,
  });

  final double t;
  final double intensity;
  final bool isDark;

  static const _colorSpeed = 1.35;

  static const _groups = <_BlobGroup>[
    _BlobGroup(
      anchorX: 0.78,
      anchorY: 0.08,
      driftX: 0.14,
      driftY: 0.12,
      freqX: 0.9,
      freqY: 1.1,
      phaseOffset: 0.0,
      radiusScale: 0.38,
      colorOffset: 0.0,
      lobes: [
        _Lobe(offsetX: 0, offsetY: 0, scale: 1.0, stretch: 1.0),
        _Lobe(offsetX: 0.12, offsetY: -0.08, scale: 0.72, stretch: 1.15),
        _Lobe(offsetX: -0.1, offsetY: 0.1, scale: 0.65, stretch: 0.9),
      ],
    ),
    _BlobGroup(
      anchorX: 0.05,
      anchorY: 0.32,
      driftX: 0.16,
      driftY: 0.14,
      freqX: 1.15,
      freqY: 0.85,
      phaseOffset: 0.17,
      radiusScale: 0.36,
      colorOffset: 0.22,
      lobes: [
        _Lobe(offsetX: 0, offsetY: 0, scale: 1.0, stretch: 1.05),
        _Lobe(offsetX: -0.14, offsetY: 0.06, scale: 0.7, stretch: 1.2),
      ],
    ),
    _BlobGroup(
      anchorX: 0.92,
      anchorY: 0.72,
      driftX: 0.13,
      driftY: 0.15,
      freqX: 0.75,
      freqY: 1.25,
      phaseOffset: 0.38,
      radiusScale: 0.4,
      colorOffset: 0.41,
      lobes: [
        _Lobe(offsetX: 0, offsetY: 0, scale: 1.0, stretch: 0.95),
        _Lobe(offsetX: 0.1, offsetY: 0.12, scale: 0.68, stretch: 1.1),
        _Lobe(offsetX: -0.08, offsetY: -0.1, scale: 0.6, stretch: 1.25),
      ],
    ),
    _BlobGroup(
      anchorX: 0.28,
      anchorY: 0.95,
      driftX: 0.15,
      driftY: 0.11,
      freqX: 1.05,
      freqY: 0.95,
      phaseOffset: 0.55,
      radiusScale: 0.34,
      colorOffset: 0.58,
      lobes: [
        _Lobe(offsetX: 0, offsetY: 0, scale: 1.0, stretch: 1.0),
        _Lobe(offsetX: 0.08, offsetY: -0.12, scale: 0.75, stretch: 0.88),
      ],
    ),
    _BlobGroup(
      anchorX: 0.48,
      anchorY: 0.45,
      driftX: 0.18,
      driftY: 0.16,
      freqX: 0.65,
      freqY: 0.7,
      phaseOffset: 0.72,
      radiusScale: 0.32,
      colorOffset: 0.74,
      lobes: [
        _Lobe(offsetX: 0, offsetY: 0, scale: 1.0, stretch: 1.08),
        _Lobe(offsetX: 0.15, offsetY: 0.05, scale: 0.62, stretch: 1.15),
        _Lobe(offsetX: -0.12, offsetY: -0.08, scale: 0.58, stretch: 0.92),
      ],
    ),
    _BlobGroup(
      anchorX: 0.62,
      anchorY: 0.58,
      driftX: 0.12,
      driftY: 0.13,
      freqX: 1.2,
      freqY: 1.0,
      phaseOffset: 0.88,
      radiusScale: 0.3,
      colorOffset: 0.9,
      lobes: [
        _Lobe(offsetX: 0, offsetY: 0, scale: 1.0, stretch: 1.0),
        _Lobe(offsetX: -0.1, offsetY: 0.14, scale: 0.66, stretch: 1.12),
      ],
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shortest = size.shortestSide;
    final tMotion = t;
    final tColor = t * _colorSpeed;

    final blend = isDark ? BlendMode.plus : BlendMode.srcOver;
    final baseAlpha = (isDark ? 0.28 : 0.16) * intensity;

    canvas.saveLayer(rect, Paint());

    for (final group in _groups) {
      final phase = tMotion + group.phaseOffset;
      final center = Offset(
        size.width * group.anchorX +
            size.width * group.driftX * _wave(phase, group.freqX),
        size.height * group.anchorY +
            size.height * group.driftY * _wave(phase + 0.31, group.freqY),
      );
      final baseRadius = shortest * group.radiusScale;
      final color = AmbientLavaPalette.colorAt(tColor + group.colorOffset);

      for (final lobe in group.lobes) {
        final lobeCenter = Offset(
          center.dx + baseRadius * lobe.offsetX,
          center.dy + baseRadius * lobe.offsetY,
        );
        final radius = baseRadius * lobe.scale;
        final alpha = baseAlpha.clamp(0.0, 1.0);

        final paint = Paint()
          ..blendMode = blend
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.42),
              color.withValues(alpha: alpha * 0.12),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.2, 0.5, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: lobeCenter,
              width: radius * 2 * lobe.stretch,
              height: radius * 2 / lobe.stretch,
            ),
          );
        canvas.drawOval(
          Rect.fromCenter(
            center: lobeCenter,
            width: radius * 2.1 * lobe.stretch,
            height: radius * 2.1 / lobe.stretch,
          ),
          paint,
        );
      }
    }

    canvas.restore();
  }

  double _wave(double phase, double freq) =>
      math.sin((phase * freq) * math.pi * 2);

  @override
  bool shouldRepaint(covariant _LavaAmbientPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isDark != isDark;
  }
}

class _BlobGroup {
  const _BlobGroup({
    required this.anchorX,
    required this.anchorY,
    required this.driftX,
    required this.driftY,
    required this.freqX,
    required this.freqY,
    required this.phaseOffset,
    required this.radiusScale,
    required this.colorOffset,
    required this.lobes,
  });

  final double anchorX;
  final double anchorY;
  final double driftX;
  final double driftY;
  final double freqX;
  final double freqY;
  final double phaseOffset;
  final double radiusScale;
  final double colorOffset;
  final List<_Lobe> lobes;
}

class _Lobe {
  const _Lobe({
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.stretch,
  });

  final double offsetX;
  final double offsetY;
  final double scale;
  final double stretch;
}

/// Exposes ambient motion phase to descendants (e.g. FAB glow, hub tiles).
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
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final phase = AmbientMotionScope.maybeOf(context);

    if (phase == null || !LinkvaultGradients.enabled(context)) {
      return _FabGlowStack(phaseValue: 0, child: child);
    }

    return AnimatedBuilder(
      animation: phase,
      builder: (context, child) {
        final pulse = 0.7 + 0.3 * math.sin(phase.value * math.pi * 2);
        return _FabGlowStack(
          phaseValue: phase.value * 1.35 + (pulse - 0.7) * 0.15,
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
    required this.phaseValue,
    required this.child,
    this.pulse = 1.0,
  });

  final double phaseValue;
  final double pulse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final warm = AmbientLavaPalette.colorAt(phaseValue);
    final cool = AmbientLavaPalette.colorAt(phaseValue + 0.33);
    final t = ((pulse - 0.4) / 0.6).clamp(0.0, 1.0);

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
                  color: warm.withValues(alpha: 0.08 + 0.1 * pulse),
                  blurRadius: lerpDouble(18, 28, t)!,
                  spreadRadius: lerpDouble(0, 1.5, t)!,
                ),
                BoxShadow(
                  color: cool.withValues(alpha: 0.05 + 0.07 * pulse),
                  blurRadius: lerpDouble(24, 38, t)!,
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
