import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/ambient_lava_palette.dart';
import '../theme/app_motion.dart';
import '../theme/linkvault_gradients.dart';

/// Top aurora ambient: large soft light bands drift slowly through the palette.
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

  static const _colorSpeed = 0.85;

  /// Three wide bands along the top edge — aurora-style, not dot clusters.
  static const _groups = <_BlobGroup>[
    _BlobGroup(
      anchorX: 0.22,
      anchorY: 0.02,
      driftX: 0.06,
      driftY: 0.03,
      freqX: 0.12,
      freqY: 0.08,
      phaseOffset: 0.0,
      radiusScale: 0.72,
      colorOffset: 0.0,
      stretch: 1.35,
    ),
    _BlobGroup(
      anchorX: 0.52,
      anchorY: 0.06,
      driftX: 0.05,
      driftY: 0.025,
      freqX: 0.1,
      freqY: 0.1,
      phaseOffset: 0.33,
      radiusScale: 0.78,
      colorOffset: 0.38,
      stretch: 1.5,
    ),
    _BlobGroup(
      anchorX: 0.8,
      anchorY: 0.04,
      driftX: 0.055,
      driftY: 0.02,
      freqX: 0.11,
      freqY: 0.09,
      phaseOffset: 0.66,
      radiusScale: 0.68,
      colorOffset: 0.62,
      stretch: 1.28,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shortest = size.shortestSide;
    final tMotion = t;
    final tColor = t * _colorSpeed;

    final blend = isDark ? BlendMode.plus : BlendMode.srcOver;
    final peakAlpha = (isDark ? 0.2 : 0.12) * intensity;

    canvas.saveLayer(rect, Paint());

    for (final group in _groups) {
      final phase = tMotion + group.phaseOffset;
      final center = Offset(
        size.width * group.anchorX +
            size.width * group.driftX * _wave(phase, group.freqX),
        size.height * group.anchorY +
            size.height * group.driftY * _wave(phase + 0.31, group.freqY),
      );
      final radius = shortest * group.radiusScale;
      final color = AmbientLavaPalette.colorAt(tColor + group.colorOffset);

      final paint = Paint()
        ..blendMode = blend
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: peakAlpha * 0.15),
            color.withValues(alpha: peakAlpha),
            color.withValues(alpha: peakAlpha * 0.35),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.32, 0.48, 0.72, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: center,
            width: radius * 2.2 * group.stretch,
            height: radius * 2.6,
          ),
        );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2.3 * group.stretch,
          height: radius * 2.7,
        ),
        paint,
      );
    }

    // Fade glow toward the bottom so the aura reads as top-weighted.
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF),
            const Color(0x66FFFFFF),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.35, 0.58, 1.0],
        ).createShader(rect),
    );

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
    required this.stretch,
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
          phaseValue: phase.value * 0.85 + (pulse - 0.7) * 0.1,
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
