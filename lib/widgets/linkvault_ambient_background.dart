import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/linkvault_gradients.dart';
import 'linkvault_animated_ambient.dart';

/// Scaffold body with solid surface base and slowly animated ambient glow.
class LinkvaultAmbientBackground extends StatelessWidget {
  const LinkvaultAmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        LinkvaultAnimatedAmbient(intensity: intensity),
        child,
      ],
    );
  }
}

/// Scaffold with shared ambient motion (background + FAB glow stay in sync).
class LinkvaultAmbientScaffold extends StatefulWidget {
  const LinkvaultAmbientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.ambientIntensity = 1.0,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final double ambientIntensity;

  @override
  State<LinkvaultAmbientScaffold> createState() =>
      _LinkvaultAmbientScaffoldState();
}

class _LinkvaultAmbientScaffoldState extends State<LinkvaultAmbientScaffold>
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

    Widget scaffold = Scaffold(
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      appBar: widget.appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: scheme.surface),
          if (phase != null)
            LinkvaultAnimatedAmbient(
              intensity: widget.ambientIntensity,
              phase: phase,
            )
          else
            LinkvaultAnimatedAmbient(intensity: widget.ambientIntensity),
          widget.body,
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );

    if (phase != null) {
      scaffold = AmbientMotionScope(phase: phase, child: scaffold);
    }

    return scaffold;
  }
}
