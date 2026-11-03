import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('NexiozaEmptyState', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaEmptyState(
            icon: Icons.inbox,
            title: 'No Items',
            message: 'Nothing here yet.',
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaEmptyState(
            icon: Icons.inbox,
            title: 'No Items',
            message: 'Nothing here yet.',
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
    });

    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaEmptyState(
            icon: Icons.inbox,
            title: 'No Items',
            message: 'Nothing here yet.',
          ),
        ),
      );

      expect(find.text('Nothing here yet.'), findsOneWidget);
    });

    testWidgets('renders action button when actionLabel is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          NexiozaEmptyState(
            icon: Icons.inbox,
            title: 'No Items',
            message: 'Nothing here yet.',
            actionLabel: 'Create',
            onAction: () {},
          ),
        ),
      );

      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('does not render action button when actionLabel is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const NexiozaEmptyState(
            icon: Icons.inbox,
            title: 'No Items',
            message: 'Nothing here yet.',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
