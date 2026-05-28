import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/update_config.dart';

/// Parsed update manifest shipped with each GitHub Release.
class UpdateManifest {
  const UpdateManifest({
    required this.versionName,
    required this.versionCode,
    required this.apkFileName,
    required this.sha256,
    required this.apkDownloadUrl,
    this.releaseNotes,
    this.publishedAt,
  });

  final String versionName;
  final int versionCode;
  final String apkFileName;
  final String sha256;
  final String apkDownloadUrl;
  final String? releaseNotes;
  final String? publishedAt;

  factory UpdateManifest.fromJson(
    Map<String, dynamic> json, {
    required String apkDownloadUrl,
    String? releaseNotes,
  }) {
    return UpdateManifest(
      versionName: json['versionName'] as String,
      versionCode: (json['versionCode'] as num).toInt(),
      apkFileName: json['apkFileName'] as String,
      sha256: (json['sha256'] as String).toLowerCase(),
      apkDownloadUrl: apkDownloadUrl,
      releaseNotes: releaseNotes,
      publishedAt: json['publishedAt'] as String?,
    );
  }

  static UpdateManifest parseManifestJson(
    String body, {
    required String apkDownloadUrl,
    String? releaseNotes,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return UpdateManifest.fromJson(
      json,
      apkDownloadUrl: apkDownloadUrl,
      releaseNotes: releaseNotes,
    );
  }
}

enum UpdateCheckResult {
  upToDate,
  updateAvailable,
  error,
}

class UpdateCheckResponse {
  const UpdateCheckResponse({
    required this.result,
    this.manifest,
    this.currentVersionName,
    this.currentVersionCode,
    this.errorMessage,
  });

  final UpdateCheckResult result;
  final UpdateManifest? manifest;
  final String? currentVersionName;
  final int? currentVersionCode;
  final String? errorMessage;
}

class DownloadProgress {
  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction =>
      totalBytes != null && totalBytes! > 0 ? receivedBytes / totalBytes! : null;
}

typedef AppVersionInfo = ({String versionName, int versionCode});

/// Checks GitHub Releases and downloads verified APKs for sideload install.
class AppUpdateService {
  AppUpdateService({
    http.Client? client,
    Future<AppVersionInfo> Function()? currentVersion,
  })  : _client = client ?? http.Client(),
        _currentVersion = currentVersion ?? _defaultCurrentVersion;

  final http.Client _client;
  final Future<AppVersionInfo> Function() _currentVersion;

  static Future<AppVersionInfo> _defaultCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return (
      versionName: packageInfo.version,
      versionCode: int.tryParse(packageInfo.buildNumber) ?? 0,
    );
  }

  static const _allowedHosts = {'github.com', 'api.github.com'};

  static bool isAllowedDownloadUrl(Uri uri) {
    if (uri.scheme != 'https') return false;
    if (_allowedHosts.contains(uri.host)) return true;
    if (uri.host.endsWith('.githubusercontent.com')) return true;
    return false;
  }

  static bool isAllowedLocalUrl(Uri uri) {
    if (!useLocalUpdateServer) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final base = Uri.parse(kUpdateBaseUrl);
    return uri.host == base.host && uri.port == base.port;
  }

  Future<UpdateCheckResponse> checkForUpdate() async {
    try {
      final current = await _currentVersion();

      final manifest = await _fetchLatestManifest();
      if (manifest == null) {
        return UpdateCheckResponse(
          result: UpdateCheckResult.error,
          currentVersionName: current.versionName,
          currentVersionCode: current.versionCode,
          errorMessage: 'Could not read update information.',
        );
      }

      if (manifest.versionCode <= current.versionCode) {
        return UpdateCheckResponse(
          result: UpdateCheckResult.upToDate,
          manifest: manifest,
          currentVersionName: current.versionName,
          currentVersionCode: current.versionCode,
        );
      }

      return UpdateCheckResponse(
        result: UpdateCheckResult.updateAvailable,
        manifest: manifest,
        currentVersionName: current.versionName,
        currentVersionCode: current.versionCode,
      );
    } catch (e) {
      return UpdateCheckResponse(
        result: UpdateCheckResult.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<UpdateManifest?> _fetchLatestManifest() async {
    if (useLocalUpdateServer) {
      return _fetchLocalManifest();
    }
    return _fetchGithubManifest();
  }

  Future<UpdateManifest?> _fetchLocalManifest() async {
    final url = localUpdateManifestUrl(kUpdateBaseUrl);
    final uri = Uri.parse(url);
    if (!isAllowedLocalUrl(uri)) {
      throw StateError('Local update URL not permitted: $url');
    }
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw HttpException('Manifest HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final apkUrl = '${uri.origin}/${json['apkFileName']}';
    return UpdateManifest.fromJson(json, apkDownloadUrl: apkUrl);
  }

  Future<UpdateManifest?> _fetchGithubManifest() async {
    final releaseResponse = await _client.get(
      Uri.parse(githubLatestReleaseApiUrl),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (releaseResponse.statusCode != 200) {
      throw HttpException('GitHub API HTTP ${releaseResponse.statusCode}');
    }

    final release = jsonDecode(releaseResponse.body) as Map<String, dynamic>;
    final releaseNotes = release['body'] as String?;
    final assets = release['assets'] as List<dynamic>? ?? [];

    String? manifestUrl;
    String? apkUrl;
    String? apkFileName;

    for (final asset in assets) {
      final map = asset as Map<String, dynamic>;
      final name = map['name'] as String;
      final url = map['browser_download_url'] as String;
      if (name == 'linkvault-update.json') {
        manifestUrl = url;
      } else if (name.startsWith('linkvault-') && name.endsWith('.apk')) {
        apkUrl = url;
        apkFileName = name;
      }
    }

    if (manifestUrl != null) {
      final manifestUri = Uri.parse(manifestUrl);
      if (!isAllowedDownloadUrl(manifestUri)) {
        throw StateError('Manifest URL not allowed');
      }
      final manifestResponse = await _client.get(manifestUri);
      if (manifestResponse.statusCode != 200) {
        throw HttpException('Manifest HTTP ${manifestResponse.statusCode}');
      }
      final json =
          jsonDecode(manifestResponse.body) as Map<String, dynamic>;
      String? resolvedApkUrl = apkUrl;
      if (resolvedApkUrl == null) {
        final wanted = json['apkFileName'] as String?;
        for (final asset in assets) {
          final map = asset as Map<String, dynamic>;
          if (map['name'] == wanted) {
            resolvedApkUrl = map['browser_download_url'] as String;
            break;
          }
        }
      }
      if (resolvedApkUrl == null) {
        return null;
      }
      return UpdateManifest.fromJson(
        json,
        apkDownloadUrl: resolvedApkUrl,
        releaseNotes: releaseNotes,
      );
    }

    // Fallback: tag name + APK asset only
    final tag = (release['tag_name'] as String?)?.replaceFirst(RegExp(r'^v'), '');
    if (tag == null || apkUrl == null) return null;

    final apkUri = Uri.parse(apkUrl);
    if (!isAllowedDownloadUrl(apkUri)) {
      throw StateError('APK URL not allowed');
    }

    return UpdateManifest(
      versionName: tag,
      versionCode: 0,
      apkFileName: apkFileName ?? 'linkvault-$tag.apk',
      sha256: '',
      apkDownloadUrl: apkUrl,
      releaseNotes: releaseNotes,
    );
  }

  Future<File> downloadApk(
    UpdateManifest manifest, {
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final uri = Uri.parse(manifest.apkDownloadUrl);
    if (!isAllowedDownloadUrl(uri) && !isAllowedLocalUrl(uri)) {
      throw StateError('Download URL not allowed: ${manifest.apkDownloadUrl}');
    }

    final request = http.Request('GET', uri);
    final streamed = await _client.send(request);
    if (streamed.statusCode != 200) {
      throw HttpException('Download HTTP ${streamed.statusCode}');
    }

    final total = streamed.contentLength;
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, manifest.apkFileName));
    final sink = file.openWrite();
    var received = 0;

    await for (final chunk in streamed.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(DownloadProgress(
        receivedBytes: received,
        totalBytes: (total ?? 0) > 0 ? total : null,
      ));
    }
    await sink.close();

    if (manifest.sha256.isNotEmpty) {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != manifest.sha256.toLowerCase()) {
        await file.delete();
        throw StateError('APK checksum mismatch');
      }
    }

    return file;
  }

  void close() => _client.close();
}
