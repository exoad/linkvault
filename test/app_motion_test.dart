import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/theme/app_motion.dart';

void main() {
  testWidgets('motionEnabled is false when disableAnimations is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              return Text(
                motionEnabled(context) ? 'on' : 'off',
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('off'), findsOneWidget);
  });

  testWidgets('motionEnabled is true by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Text(motionEnabled(context) ? 'on' : 'off');
          },
        ),
      ),
    );

    expect(find.text('on'), findsOneWidget);
  });
}
