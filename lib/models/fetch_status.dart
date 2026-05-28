enum FetchStatus {
  pending,
  success,
  failed,
  skippedOffline,
}

extension FetchStatusX on FetchStatus {
  String get storageValue => name;

  static FetchStatus fromStorage(String value) {
    return FetchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FetchStatus.pending,
    );
  }
}
