import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last-opened chat session id.
class ChatSessionPreferences {
  ChatSessionPreferences(this._prefs);

  static const _activeSessionKey = 'chat_active_session_id';

  final SharedPreferences _prefs;

  static Future<ChatSessionPreferences> load() async {
    return ChatSessionPreferences(await SharedPreferences.getInstance());
  }

  String? get activeSessionId => _prefs.getString(_activeSessionKey);

  Future<void> setActiveSessionId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeSessionKey);
    } else {
      await _prefs.setString(_activeSessionKey, id);
    }
  }
}
