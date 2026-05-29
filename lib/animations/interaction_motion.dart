import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';

/// Subtle press scale + optional fade for tappable surfaces.
class AlivePressable extends StatefulWidget {
  const AlivePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.borderRadius,
    this.enabled = true,
    this.pressedScale = AppMotion.pressScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final BorderRadius? borderRadius;
  final bool enabled;
  final double pressedScale;

  @override
  State<AlivePressable> createState() => _AlivePressableState();
}

class _AlivePressableState extends State<AlivePressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || !motionEnabled(context)) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
    widget.onHighlightChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    final motion = motionEnabled(context);

    Widget child = widget.child;
    if (interactive && motion) {
      child = AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppMotion.micro,
        curve: AppMotion.spring,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.94 : 1,
          duration: AppMotion.micro,
          curve: AppMotion.standard,
          child: child,
        ),
      );
    }

    if (!interactive) return child;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: _setPressed,
        borderRadius: widget.borderRadius,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: child,
      ),
    );
  }
}

/// App bar / trailing control with a soft press shrink.
class AliveIconButton extends StatefulWidget {
  const AliveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<AliveIconButton> createState() => _AliveIconButtonState();
}

class _AliveIconButtonState extends State<AliveIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = motionEnabled(context);
    final icon = motion
        ? AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: AppMotion.micro,
            curve: AppMotion.spring,
            child: widget.icon,
          )
        : widget.icon;

    final button = IconButton(
      tooltip: widget.tooltip,
      onPressed: widget.onPressed,
      icon: icon,
    );

    if (!motion) return button;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: button,
    );
  }
}

extension AliveMotion on Widget {
  /// Staggered fade + slide for list/grid children.
  Widget listEntrance(
    BuildContext context, {
    required int index,
    Duration? delay,
  }) {
    if (!motionEnabled(context)) return this;
    final stagger = delay ?? AppMotion.staggerDelay(index);
    return animate()
        .fadeIn(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          delay: stagger,
        )
        .slideY(
          begin: 0.06,
          end: 0,
          duration: AppMotion.normal,
          curve: AppMotion.decelerate,
          delay: stagger,
        )
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: AppMotion.normal,
          curve: AppMotion.decelerate,
          delay: stagger,
        );
  }

  /// Gentle entrance for headers and hero blocks.
  Widget heroEntrance(BuildContext context) {
    if (!motionEnabled(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.slow, curve: AppMotion.decelerate)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.decelerate,
        );
  }

  /// Subtle continuous breathe (e.g. primary FAB).
  Widget aliveBreathe(BuildContext context) {
    if (!motionEnabled(context)) return this;
    return animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: AppMotion.breathe,
          curve: AppMotion.emphasized,
        );
  }
}

/// Cross-fades [child] when [value] changes — for stats, labels, toggles.
Widget aliveFadeSwap({
  required Object value,
  required Widget child,
  Duration duration = AppMotion.normal,
}) {
  return AnimatedSwitcher(
    duration: duration,
    switchInCurve: AppMotion.decelerate,
    switchOutCurve: AppMotion.standard,
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
    child: KeyedSubtree(
      key: ValueKey(value),
      child: child,
    ),
  );
}
