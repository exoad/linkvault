import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/linkvault_gradients.dart';
import 'film_grain.dart';
import 'linkvault_animated_ambient.dart';

/// App-wide ambient backdrop (surface, lava glow, grain). Lives above the
/// navigator so route changes do not restart motion or repaint a new stack.
class AmbientShell extends StatefulWidget {
  const AmbientShell({
    super.key,
    required this.child,
    this.intensity = LinkvaultGradients.ambientIntensity,
  });

  final Widget child;
  final double intensity;

  @override
  State<AmbientShell> createState() => _AmbientShellState();
}

class _AmbientShellState extends State<AmbientShell>
    with SingleTickerProviderStateMixin {
  AnimationController? _phase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPhase();
  }

  void _syncPhase() {
    final shouldAnimate = LinkvaultGradients.enabled(context);
    if (!shouldAnimate) {
      _phase?.stop();
      return;
    }

    _phase ??= AnimationController(
      vsync: this,
      duration: AppMotion.ambientCycle,
    )..repeat();

    if (!_phase!.isAnimating) {
      _phase!.repeat();
    }
  }

  @override
  void dispose() {
    _phase?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = _phase;

    Widget backdrop = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        if (phase != null)
          LinkvaultAnimatedAmbient(
            intensity: widget.intensity,
            phase: phase,
          )
        else
          LinkvaultAnimatedAmbient(intensity: widget.intensity),
        const FilmGrain(),
      ],
    );

    backdrop = IgnorePointer(child: backdrop);

    Widget stack = Stack(
      fit: StackFit.expand,
      children: [
        backdrop,
        widget.child,
      ],
    );

    if (phase != null) {
      stack = AmbientMotionScope(phase: phase, child: stack);
    }

    return stack;
  }
}

/// Legacy wrapper; ambient is provided by [AmbientShell] at the app root.
class LinkvaultAmbientBackground extends StatelessWidget {
  const LinkvaultAmbientBackground({
    super.key,
    required this.child,
    this.intensity = LinkvaultGradients.ambientIntensity,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) => child;
}

/// Scaffold with transparent background so the global ambient shell shows through.
class LinkvaultAmbientScaffold extends StatelessWidget {
  const LinkvaultAmbientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.ambientIntensity = LinkvaultGradients.ambientIntensity,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final double ambientIntensity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
