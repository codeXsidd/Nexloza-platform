import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/features/settings/presentation/screens/settings_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders Settings title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders theme mode options', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('renders version info', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.textContaining('0.1.0'), findsOneWidget);
    });
  });
}
