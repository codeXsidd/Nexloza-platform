import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/models/organization.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/home/presentation/screens/home_screen.dart';
import 'package:nexioza/features/organizations/presentation/providers/organization_provider.dart';
import 'package:nexioza/features/projects/presentation/providers/project_provider.dart';

void main() {
  Widget buildTestWidget({
    List<Project> projects = const [],
    List<Organization> orgs = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        projectsProvider.overrideWith((_) async => projects),
        organizationsProvider.overrideWith((_) async => orgs),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders greeting text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('renders stat cards', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('Organizations'), findsWidgets);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Automations'), findsOneWidget);
    });

    testWidgets('shows correct project count', (tester) async {
      final projects = [
        Project(
          id: '1',
          organizationId: 'org1',
          name: 'Test',
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(buildTestWidget(projects: projects));
      await tester.pump();
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('renders navigation cards', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.text('Orgs'), findsOneWidget);
    });
  });
}
