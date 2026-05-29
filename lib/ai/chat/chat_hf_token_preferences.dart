import 'package:shared_preferences/shared_preferences.dart';

/// Optional Hugging Face token for gated model downloads.
class ChatHfTokenPreferences {
  ChatHfTokenPreferences(this._prefs);

  static const _key = 'chat_huggingface_token';

  final SharedPreferences _prefs;

  static Future<ChatHfTokenPreferences> load() async {
    return ChatHfTokenPreferences(await SharedPreferences.getInstance());
  }

  String? get token {
    final value = _prefs.getString(_key)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setToken(String? token) async {
    final trimmed = token?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, trimmed);
    }
  }
}
