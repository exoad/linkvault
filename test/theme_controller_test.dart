import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads persisted theme preferences', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'use_dynamic_color': false,
      'seed_color_argb': 0xFF112233,
    });

    final controller = ThemeController();
    await controller.load();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.useDynamicColor, isFalse);
    expect(controller.seedColor, const Color(0xFF112233));
  });

  test('persists theme mode and seed color updates', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = ThemeController();
    await controller.load();
    expect(controller.themeMode, ThemeMode.system);
    expect(controller.useDynamicColor, isTrue);

    await controller.setThemeMode(ThemeMode.light);
    await controller.setUseDynamicColor(false);
    await controller.setSeedColor(Colors.teal);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
    expect(prefs.getBool('use_dynamic_color'), isFalse);
    expect(prefs.getInt('seed_color_argb'), Colors.teal.toARGB32());
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.useDynamicColor, isFalse);
    expect(controller.seedColor, Colors.teal);
  });
}
