import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../services/apk_installer.dart';
import '../../services/app_update_service.dart';
import '../../widgets/settings_group.dart';

class UpdateSection extends StatefulWidget {
  const UpdateSection({super.key});

  @override
  State<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<UpdateSection> {
  final _updateService = AppUpdateService();
  PackageInfo? _packageInfo;
  UpdateCheckResponse? _lastCheck;
  bool _checking = false;
  bool _downloading = false;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _updateService.close();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checking = true;
      _lastCheck = null;
    });
    final response = await _updateService.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _lastCheck = response;
    });

    switch (response.result) {
      case UpdateCheckResult.upToDate:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the latest version.')),
        );
      case UpdateCheckResult.updateAvailable:
        break;
      case UpdateCheckResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.errorMessage ?? 'Update check failed.',
            ),
          ),
        );
    }
  }

  Future<void> _downloadAndInstall(UpdateManifest manifest) async {
    if (!Platform.isAndroid) return;

    final notes = manifest.releaseNotes?.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${manifest.versionName}?'),
        content: SingleChildScrollView(
          child: Text(
            notes != null && notes.isNotEmpty
                ? notes.length > 500
                    ? '${notes.substring(0, 500)}…'
                    : notes
                : 'Download and install this update?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Install'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (!await ApkInstaller.canInstallPackages()) {
      if (!mounted) return;
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow app installs'),
          content: const Text(
            'Linkvault needs permission to install updates. On the next '
            'screen, turn on “Allow from this source” (or “Install unknown apps”), '
            'then return here and tap Download and install again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await ApkInstaller.openInstallPermissionSettings();
      }
      return;
    }

    setState(() {
      _downloading = true;
      _downloadProgress = null;
    });

    try {
      final file = await _updateService.downloadApk(
        manifest,
        onProgress: (p) {
          if (mounted) {
            setState(() => _downloadProgress = p.fraction);
          }
        },
      );
      await ApkInstaller.install(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Follow the system prompt to complete installation.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _packageInfo?.version ?? '…';
    final build = _packageInfo?.buildNumber ?? '';
    final manifest = _lastCheck?.manifest;
    final updateAvailable = _lastCheck?.result ==
            UpdateCheckResult.updateAvailable &&
        manifest != null;

    return SettingsGroup(
      title: 'Updates',
      children: [
        ListTile(
          leading: PhosphorIcon(PhosphorIcons.info),
          title: const Text('Installed version'),
          subtitle: Text(build.isEmpty ? version : '$version (build $build)'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.tonalIcon(
                onPressed: _checking || _downloading ? null : _checkForUpdates,
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PhosphorIcon(PhosphorIcons.arrowsClockwise),
                label: Text(_checking ? 'Checking…' : 'Check for updates'),
              ),
              if (_downloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 6),
                Text(
                  _downloadProgress != null
                      ? '${(_downloadProgress! * 100).toStringAsFixed(0)}% downloaded'
                      : 'Downloading…',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        if (updateAvailable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Version ${manifest.versionName} available',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _downloading
                          ? null
                          : () => _downloadAndInstall(manifest),
                      child: const Text('Download and install'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
