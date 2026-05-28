import 'package:shared_preferences/shared_preferences.dart';

import '../models/layout_mode.dart';

class LayoutPreferences {
  static const _key = 'bookmark_layout_mode';

  Future<LayoutMode> getLayoutMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) return LayoutMode.list;
    return LayoutModeX.fromStorage(value);
  }

  Future<void> setLayoutMode(LayoutMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.storageValue);
  }
}
