import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app_scope.dart';
import '../../services/data_export_service.dart';
import '../../animations/interaction_motion.dart';
import '../../theme/linkvault_design.dart';
import '../../widgets/settings_group.dart';

class DataSection extends StatefulWidget {
  const DataSection({super.key});

  @override
  State<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<DataSection> {
  bool _exporting = false;

  Future<void> _exportAll() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final database = AppScope.databaseOf(context);
      await DataExportService(database).exportAndShare();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready to share.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsGroup(
      title: 'Data',
      children: [
        ListTile(
          leading: aliveFadeSwap(
            value: _exporting,
            child: _exporting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : PhosphorIcon(PhosphorIcons.export, color: scheme.primary),
          ),
          title: const Text('Export all data'),
          subtitle: const Text(
            'Links, notes, and chats as a JSON file on this device.',
          ),
          enabled: !_exporting,
          onTap: _exporting ? null : _exportAll,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LinkvaultDesign.spaceLg,
            0,
            LinkvaultDesign.spaceLg,
            LinkvaultDesign.spaceLg,
          ),
          child: Text(
            'Includes folder PIN hashes if set. Import is not supported yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
        ),
      ],
    );
  }
}
