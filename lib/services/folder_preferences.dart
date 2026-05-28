import 'package:shared_preferences/shared_preferences.dart';

class FolderPreferences {
  static const _lastFolderKey = 'last_used_folder_id';

  Future<String?> getLastFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastFolderKey);
  }

  Future<void> setLastFolderId(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFolderKey, folderId);
  }
}
