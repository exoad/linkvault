import 'fetch_status.dart';

class BookmarkModel {
  const BookmarkModel({
    required this.id,
    required this.folderId,
    required this.url,
    required this.title,
    required this.fetchStatus,
    required this.createdAt,
    this.fetchedAt,
  });

  final String id;
  final String folderId;
  final String url;
  final String title;
  final FetchStatus fetchStatus;
  final DateTime? fetchedAt;
  final DateTime createdAt;

  bool get needsFetch =>
      fetchStatus == FetchStatus.skippedOffline ||
      fetchStatus == FetchStatus.failed;

  bool get isFetching => fetchStatus == FetchStatus.pending;
}
