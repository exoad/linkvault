import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linkvault/services/app_update_service.dart';

void main() {
  group('AppUpdateService', () {
    test('isAllowedDownloadUrl accepts github hosts', () {
      expect(
        AppUpdateService.isAllowedDownloadUrl(
          Uri.parse(
            'https://github.com/exoad/linkvault/releases/download/v1/apk',
          ),
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isAllowedDownloadUrl(
          Uri.parse(
            'https://release-assets.githubusercontent.com/foo/apk',
          ),
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isAllowedDownloadUrl(
          Uri.parse('https://evil.com/apk'),
        ),
        isFalse,
      );
    });

    test('parseManifestJson reads version fields', () {
      final manifest = UpdateManifest.parseManifestJson(
        jsonEncode({
          'versionName': '1.0.1',
          'versionCode': 2,
          'apkFileName': 'linkvault-1.0.1.apk',
          'sha256': 'deadbeef',
        }),
        apkDownloadUrl: 'https://github.com/x/y/releases/download/v1.0.1/a.apk',
      );
      expect(manifest.versionName, '1.0.1');
      expect(manifest.versionCode, 2);
      expect(manifest.sha256, 'deadbeef');
    });

    test('checkForUpdate fetches manifest from GitHub release assets', () async {
      final manifestJson = {
        'versionName': '9.9.9',
        'versionCode': 99999,
        'apkFileName': 'linkvault-9.9.9.apk',
        'sha256': 'abc',
      };

      final client = MockClient((request) async {
        if (request.url.path.contains('releases/latest')) {
          return http.Response(
            jsonEncode({
              'tag_name': 'v9.9.9',
              'body': 'Test release',
              'assets': [
                {
                  'name': 'linkvault-update.json',
                  'browser_download_url':
                      'https://github.com/exoad/linkvault/releases/download/v9.9.9/linkvault-update.json',
                },
                {
                  'name': 'linkvault-9.9.9.apk',
                  'browser_download_url':
                      'https://github.com/exoad/linkvault/releases/download/v9.9.9/linkvault-9.9.9.apk',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('linkvault-update.json')) {
          return http.Response(jsonEncode(manifestJson), 200);
        }
        return http.Response('not found', 404);
      });

      final service = AppUpdateService(
        client: client,
        currentVersion: () async => (versionName: '1.0.0', versionCode: 1),
      );
      addTearDown(service.close);

      final response = await service.checkForUpdate();
      expect(response.result, UpdateCheckResult.updateAvailable);
      expect(response.manifest?.versionName, '9.9.9');
      expect(response.manifest?.versionCode, 99999);
    });

    test('downloadApk rejects disallowed URL', () async {
      final service = AppUpdateService();
      addTearDown(service.close);

      final manifest = UpdateManifest(
        versionName: '1.0.0',
        versionCode: 2,
        apkFileName: 'bad.apk',
        sha256: '',
        apkDownloadUrl: 'https://evil.example/bad.apk',
      );

      expect(
        () => service.downloadApk(manifest),
        throwsA(isA<StateError>()),
      );
    });
  });
}
