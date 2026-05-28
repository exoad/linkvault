import 'package:flutter/material.dart';

/// Swaps list/grid layouts instantly — no cross-fade (avoids full-screen flicker).
class LayoutSwitcher extends StatelessWidget {
  const LayoutSwitcher({
    super.key,
    required this.layoutKey,
    required this.child,
  });

  final Object layoutKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(layoutKey),
      child: child,
    );
  }
}
