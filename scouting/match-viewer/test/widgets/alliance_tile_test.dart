import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/widgets/alliance_tile.dart';

void main() {
  const alliance = Alliance(
    eventKey: '2026mimid',
    allianceNumber: 1,
    name: 'Alliance 1',
    picks: ['frc201', 'frc254', 'frc1678'],
  );

  Widget buildWidget({
    Alliance a = alliance,
    bool isYourAlliance = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AllianceTile(
          alliance: a,
          isYourAlliance: isYourAlliance,
          onTap: onTap,
        ),
      ),
    );
  }

  group('AllianceTile', () {
    testWidgets('displays alliance name and team numbers', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Alliance 1'), findsOneWidget);
      // Team numbers formatted as "201 · 254 · 1678"
      expect(find.text('201 \u00b7 254 \u00b7 1678'), findsOneWidget);
    });

    testWidgets('does not show star icon when isYourAlliance is true',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourAlliance: true));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('does not show star icon when isYourAlliance is false',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourAlliance: false));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows left indicator bar and background when isYourAlliance',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourAlliance: true));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.border, isNotNull);
      expect(decoration.color, isNotNull);

      // Check left border is 3px wide
      final border = decoration.border as Border;
      expect(border.left.width, 3);
    });

    testWidgets('no indicator bar or background when not your alliance',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourAlliance: false));

      final containers = find.byType(Container);
      bool foundNullDecoration = false;
      for (int i = 0; i < containers.evaluate().length; i++) {
        final widget = tester.widget<Container>(containers.at(i));
        if (widget.decoration == null &&
            widget.child is ListTile) {
          foundNullDecoration = true;
          break;
        }
      }
      expect(foundNullDecoration, isTrue);
    });

    testWidgets('filled CircleAvatar uses primary color when isYourAlliance',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourAlliance: true));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      final theme = Theme.of(tester.element(find.byType(AllianceTile)));
      expect(avatar.backgroundColor, theme.colorScheme.primary);
    });

    testWidgets('CircleAvatar shows alliance number', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('1'), findsOneWidget); // in CircleAvatar
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });
}
