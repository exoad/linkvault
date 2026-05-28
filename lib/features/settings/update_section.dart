import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../services/apk_installer.dart';
import '../../services/app_update_service.dart';

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

    if (await Permission.requestInstallPackages.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Allow installs from this app in system settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
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
            content: Text('Follow the system prompt to complete installation.'),
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
    final updateAvailable =
        _lastCheck?.result == UpdateCheckResult.updateAvailable && manifest != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: PhosphorIcon(PhosphorIcons.info),
          title: const Text('Version'),
          subtitle: Text(build.isEmpty ? version : '$version ($build)'),
        ),
        if (_downloading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _downloadProgress),
          const SizedBox(height: 4),
          Text(
            _downloadProgress != null
                ? '${(_downloadProgress! * 100).toStringAsFixed(0)}%'
                : 'Downloading…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
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
        if (updateAvailable) ...[
          const SizedBox(height: 12),
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update available: ${manifest.versionName}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
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
        ],
      ],
    );
  }
}
