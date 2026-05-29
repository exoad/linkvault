import 'package:flutter/material.dart';

import '../../theme/linkvault_design.dart';
import '../../theme/linkvault_typography.dart';
import '../../widgets/settings_group.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsGroup(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LinkvaultDesign.spaceLg,
            LinkvaultDesign.spaceLg,
            LinkvaultDesign.spaceLg,
            LinkvaultDesign.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dark canvas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: LinkvaultDesign.spaceXs),
              Text(
                'Black and white UI with a slowly cycling ambient glow. '
                'Light and system themes are not available.',
                style: LinkvaultTypography.meta(scheme),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
