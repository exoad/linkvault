import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/theme/phosphor_icon_registry.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

void main() {
  test('resolve returns known regular icons', () {
    expect(
      PhosphorIconRegistry.resolve('folder'),
      PhosphorIconsRegular.folder,
    );
    expect(
      PhosphorIconRegistry.resolve('lock'),
      PhosphorIconsRegular.lock,
    );
    expect(
      PhosphorIconRegistry.resolve('bookmark'),
      PhosphorIconsRegular.bookmark,
    );
  });

  test('resolve falls back to folder for unknown names', () {
    expect(
      PhosphorIconRegistry.resolve('not_a_real_icon_name'),
      PhosphorIconsRegular.folder,
    );
  });

  test('resolve supports bold and fill styles', () {
    expect(
      PhosphorIconRegistry.resolve('heart', style: PhosphorIconStyle.bold),
      PhosphorIconsBold.heart,
    );
    expect(
      PhosphorIconRegistry.resolve('heart', style: PhosphorIconStyle.fill),
      PhosphorIconsFill.heart,
    );
  });
}
