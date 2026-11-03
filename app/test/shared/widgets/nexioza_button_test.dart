import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/shared/widgets/nexioza_button.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NexiozaButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          NexiozaButton.primary(
            label: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          NexiozaButton.primary(
            label: 'Tap Me',
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          NexiozaButton.primary(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show label when loading', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          NexiozaButton.primary(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.text('Loading'), findsNothing);
    });
  });
}
