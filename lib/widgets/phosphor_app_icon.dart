import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/phosphor_icon_registry.dart';

class PhosphorAppIcon extends StatelessWidget {
  const PhosphorAppIcon(
    this.iconName, {
    super.key,
    this.size = 24,
    this.color,
    this.style = PhosphorIconStyle.regular,
  });

  final String iconName;
  final double size;
  final Color? color;
  final PhosphorIconStyle style;

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(
      PhosphorIconRegistry.resolve(iconName, style: style),
      size: size,
      color: color,
    );
  }
}
