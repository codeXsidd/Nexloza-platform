import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/shared/widgets/nexioza_stat_card.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('NexiozaStatCard', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaStatCard(
            label: 'Projects',
            value: '5',
            icon: Icons.folder,
          ),
        ),
      );

      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('renders value', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaStatCard(
            label: 'Projects',
            value: '5',
            icon: Icons.folder,
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaStatCard(
            label: 'Projects',
            value: '5',
            icon: Icons.folder,
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('renders trend when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaStatCard(
            label: 'Projects',
            value: '5',
            icon: Icons.folder,
            trend: '+2',
          ),
        ),
      );

      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('does not render trend when not provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaStatCard(
            label: 'Projects',
            value: '5',
            icon: Icons.folder,
          ),
        ),
      );

      final trendFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data != 'Projects' && widget.data != '5',
      );
      expect(trendFinder, findsNothing);
    });
  });
}
