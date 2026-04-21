import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/widgets/team_tile.dart';

void main() {
  const team = Team(
    eventKey: '2026mimid',
    teamNumber: 201,
    nickname: 'The FEDS',
  );

  const teamNoNickname = Team(
    eventKey: '2026mimid',
    teamNumber: 254,
  );

  Widget buildWidget({
    Team t = team,
    bool isYourTeam = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TeamTile(
          team: t,
          isYourTeam: isYourTeam,
          onTap: onTap,
        ),
      ),
    );
  }

  group('TeamTile', () {
    testWidgets('displays team number and nickname', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('201'), findsWidgets); // in CircleAvatar and title
      expect(find.text('The FEDS'), findsOneWidget);
    });

    testWidgets('hides subtitle when nickname is empty', (tester) async {
      await tester.pumpWidget(buildWidget(t: teamNoNickname));
      expect(find.text('254'), findsWidgets);
      expect(find.text(''), findsNothing);
    });

    testWidgets('does not show star icon when isYourTeam is true',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourTeam: true));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('does not show star icon when isYourTeam is false',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourTeam: false));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows left indicator bar and background when isYourTeam',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourTeam: true));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.border, isNotNull);
      expect(decoration.color, isNotNull);

      // Check left border is 3px wide
      final border = decoration.border as Border;
      expect(border.left.width, 3);
    });

    testWidgets('no indicator bar or background when not your team',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourTeam: false));

      // Find the Container wrapping the ListTile — it's the TeamTile's root Container
      final containers = find.byType(Container);
      // The first Container that is a direct child of TeamTile should have null decoration
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

    testWidgets('filled CircleAvatar uses primary color when isYourTeam',
        (tester) async {
      await tester.pumpWidget(buildWidget(isYourTeam: true));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      final theme = Theme.of(tester.element(find.byType(TeamTile)));
      expect(avatar.backgroundColor, theme.colorScheme.primary);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });
}
