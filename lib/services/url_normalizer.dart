class UrlNormalizer {
  static String? normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    var candidate = trimmed;
    if (!candidate.contains('://')) {
      candidate = 'https://$candidate';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.toLowerCase();
    if (host != 'localhost' && !host.contains('.')) return null;

    return uri.toString();
  }

  static bool isValid(String raw) => normalize(raw) != null;
}
