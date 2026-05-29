import 'package:url_launcher/url_launcher.dart';

import 'chat_tool.dart';

final class OpenUrlTool implements ChatTool {
  @override
  String get name => 'open_url';

  @override
  String get description => 'Open a valid http(s) URL in the system browser.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'url': {
            'type': 'string',
            'description': 'Full http or https URL',
          },
        },
        'required': ['url'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final raw = (args['url'] as String?)?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Error: url is required.';
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Error: only http and https URLs are supported.';
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched ? 'Opened $raw' : 'Could not open $raw';
  }
}
