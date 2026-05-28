import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class MetadataService {
  MetadataService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  Future<String?> fetchTitle(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 400) {
        return null;
      }

      final document = html_parser.parse(response.body);
      final ogTitle = document
          .querySelector('meta[property="og:title"]')
          ?.attributes['content']
          ?.trim();
      if (ogTitle != null && ogTitle.isNotEmpty) return ogTitle;

      final title = document.querySelector('title')?.text.trim();
      if (title != null && title.isNotEmpty) return title;

      return null;
    } catch (_) {
      return null;
    }
  }
}
