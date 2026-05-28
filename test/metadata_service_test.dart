import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linkvault/services/metadata_service.dart';

void main() {
  group('MetadataService', () {
    test('parses og:title first', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
          <html>
            <head>
              <meta property="og:title" content="OG Title" />
              <title>HTML Title</title>
            </head>
          </html>
          ''',
          200,
        );
      });

      final service = MetadataService(client: client);
      final title = await service.fetchTitle('https://example.com');
      expect(title, 'OG Title');
    });

    test('falls back to title tag', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>Page Title</title></head></html>',
          200,
        );
      });

      final service = MetadataService(client: client);
      final title = await service.fetchTitle('https://example.com');
      expect(title, 'Page Title');
    });

    test('returns null on HTTP error', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final service = MetadataService(client: client);
      expect(await service.fetchTitle('https://example.com'), isNull);
    });
  });
}
