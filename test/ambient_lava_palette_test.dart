import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/theme/ambient_lava_palette.dart';

void main() {
  test('palette has many hues', () {
    expect(AmbientLavaPalette.length, greaterThan(3));
  });

  test('colorAt wraps smoothly at phase boundaries', () {
    final c0 = AmbientLavaPalette.colorAt(0);
    final c1 = AmbientLavaPalette.colorAt(1);
    final c2 = AmbientLavaPalette.colorAt(2);
    expect(c0, c1);
    expect(c1, c2);
  });

  test('colorAt changes across the cycle', () {
    final samples = List.generate(
      12,
      (i) => AmbientLavaPalette.colorAt(i / 12),
    );
    final distinct = samples.map((c) => c.toARGB32()).toSet();
    expect(distinct.length, greaterThan(2));
  });

  test('defaultAccent provides three colors', () {
    final accent = AmbientLavaPalette.defaultAccent;
    expect(accent.primary, isA<Color>());
    expect(accent.secondary, isA<Color>());
    expect(accent.tertiary, isA<Color>());
  });
}
