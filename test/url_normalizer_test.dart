import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/services/url_normalizer.dart';

void main() {
  group('UrlNormalizer', () {
    test('adds https scheme when missing', () {
      expect(
        UrlNormalizer.normalize('example.com/page'),
        'https://example.com/page',
      );
    });

    test('preserves existing https URL', () {
      expect(
        UrlNormalizer.normalize('https://flutter.dev'),
        'https://flutter.dev',
      );
    });

    test('returns null for empty input', () {
      expect(UrlNormalizer.normalize('   '), isNull);
    });

    test('returns null for host without domain', () {
      expect(UrlNormalizer.normalize('localhostpath'), isNull);
    });

    test('isValid matches normalize', () {
      expect(UrlNormalizer.isValid('https://dart.dev'), isTrue);
      expect(UrlNormalizer.isValid('ftp://files.example'), isFalse);
    });
  });
}
