import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/features/home/presentation/screens/home_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(child: MaterialApp(home: HomeScreen()));
  }

  group('HomeScreen', () {
    testWidgets('renders greeting text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('renders stat cards', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
    });

    testWidgets('renders Get Started section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.textContaining('Create your first project'), findsOneWidget);
    });
  });
}
