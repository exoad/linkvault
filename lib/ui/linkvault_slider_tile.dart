import 'package:flutter/material.dart';

import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';

/// Labeled slider row used in model/settings sheets.
class LinkvaultSliderTile extends StatelessWidget {
  const LinkvaultSliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: LinkvaultTypography.sectionLabel(scheme)),
            const Spacer(),
            Text(display, style: LinkvaultTypography.meta(scheme)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        SizedBox(height: LinkvaultDesign.spaceXs),
      ],
    );
  }
}
