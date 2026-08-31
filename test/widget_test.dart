import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usher_app/theme/app_theme.dart';

void main() {
  testWidgets('DribbbleGlassContainer renders child and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DribbbleGlassContainer(
            onTap: () => tapped = true,
            padding: const EdgeInsets.all(16),
            child: const Text('Guardians Usher Portal'),
          ),
        ),
      ),
    );

    expect(find.text('Guardians Usher Portal'), findsOneWidget);

    await tester.tap(find.text('Guardians Usher Portal'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('DribbbleGlowButton renders label and triggers callback', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DribbbleGlowButton(
            label: 'Submit Headcount',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Submit Headcount'), findsOneWidget);

    await tester.tap(find.text('Submit Headcount'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('DribbblePillBadge displays label text accurately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DribbblePillBadge(
            label: 'ADMIN APPROVED',
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('ADMIN APPROVED'), findsOneWidget);
  });
}
