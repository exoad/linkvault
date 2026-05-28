/// In-memory session: which locked folders the user has unlocked.
class FolderLockSession {
  final Set<String> _unlockedFolderIds = {};

  bool isUnlocked(String folderId) => _unlockedFolderIds.contains(folderId);

  void unlock(String folderId) => _unlockedFolderIds.add(folderId);

  void lock(String folderId) => _unlockedFolderIds.remove(folderId);

  void lockAll() => _unlockedFolderIds.clear();
}
