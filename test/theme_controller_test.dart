import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/theme/edge_glow_palette.dart';
import 'package:linkvault/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads persisted theme preferences', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'edge_glow_index': 2,
    });

    final controller = ThemeController();
    await controller.load();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.edgeGlowIndex, 2);
    expect(controller.edgeGlowPreset.name, 'Sunset');
  });

  test('persists theme mode and edge glow updates', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = ThemeController();
    await controller.load();
    expect(controller.themeMode, ThemeMode.system);
    expect(controller.edgeGlowIndex, EdgeGlowPalette.defaultIndex);

    await controller.setThemeMode(ThemeMode.light);
    await controller.setEdgeGlowIndex(1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
    expect(prefs.getInt('edge_glow_index'), 1);
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.edgeGlowIndex, 1);
  });

  test('migrates legacy seed color to nearest preset', () async {
    SharedPreferences.setMockInitialValues({
      'seed_color_argb': 0xFF1976D2,
    });

    final controller = ThemeController();
    await controller.load();

    expect(controller.edgeGlowIndex, EdgeGlowPalette.indexForColor(
      const Color(0xFF1976D2),
    ));
  });
}
