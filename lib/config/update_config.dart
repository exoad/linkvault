/// Compile-time configuration for GitHub Releases–based updates.
const String kGithubOwner = String.fromEnvironment(
  'GITHUB_OWNER',
  defaultValue: 'exoad',
);

const String kGithubRepo = String.fromEnvironment(
  'GITHUB_REPO',
  defaultValue: 'linkvault',
);

/// When set (e.g. local testing), fetches update manifest from this base URL
/// instead of the GitHub API. Expects `GET {base}/linkvault-update.json`.
const String kUpdateBaseUrl = String.fromEnvironment(
  'UPDATE_BASE_URL',
  defaultValue: '',
);

bool get useLocalUpdateServer => kUpdateBaseUrl.isNotEmpty;

String get githubLatestReleaseApiUrl =>
    'https://api.github.com/repos/$kGithubOwner/$kGithubRepo/releases/latest';

String localUpdateManifestUrl(String base) {
  final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$trimmed/linkvault-update.json';
}
