import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/features/projects/presentation/providers/project_provider.dart';
import 'package:nexioza/features/projects/presentation/screens/projects_screen.dart';

void main() {
  Widget buildTestWidget({List<Project> projects = const []}) {
    return ProviderScope(
      overrides: [projectsProvider.overrideWith((_) async => projects)],
      child: const MaterialApp(home: ProjectsScreen()),
    );
  }

  group('ProjectsScreen', () {
    testWidgets('shows empty state when no projects', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('shows project cards when projects exist', (tester) async {
      final projects = [
        Project(
          id: '1',
          organizationId: 'org1',
          name: 'Smart Home',
          description: 'My smart home project',
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Project(
          id: '2',
          organizationId: 'org1',
          name: 'Industrial IoT',
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(buildTestWidget(projects: projects));
      await tester.pump();
      expect(find.text('Smart Home'), findsOneWidget);
      expect(find.text('Industrial IoT'), findsOneWidget);
    });

    testWidgets('has FAB for creating projects', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('has templates button in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.byIcon(Icons.dashboard_customize_outlined), findsOneWidget);
    });
  });
}
