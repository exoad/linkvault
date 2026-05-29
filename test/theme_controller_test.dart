import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/theme/ambient_lava_palette.dart';
import 'package:linkvault/theme/theme_controller.dart';

void main() {
  test('exposes default ambient accent colors', () {
    final controller = ThemeController();
    expect(controller.accent.primary, AmbientLavaPalette.colorAt(0));
    expect(controller.accent.secondary, AmbientLavaPalette.colorAt(0.33));
  });
}
