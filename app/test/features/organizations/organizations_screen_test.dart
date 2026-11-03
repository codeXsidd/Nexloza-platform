import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/models/organization.dart';
import 'package:nexioza/features/organizations/presentation/providers/organization_provider.dart';
import 'package:nexioza/features/organizations/presentation/screens/organizations_screen.dart';

void main() {
  Widget buildTestWidget({List<Organization> orgs = const []}) {
    return ProviderScope(
      overrides: [organizationsProvider.overrideWith((_) async => orgs)],
      child: const MaterialApp(home: OrganizationsScreen()),
    );
  }

  group('OrganizationsScreen', () {
    testWidgets('shows empty state when no organizations', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.text('No organizations'), findsOneWidget);
    });

    testWidgets('shows organization cards', (tester) async {
      final orgs = [
        Organization(
          id: '1',
          name: 'Acme Corp',
          ownerId: 'u1',
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          memberRole: 'owner',
          memberCount: 3,
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orgs: orgs));
      await tester.pump();
      expect(find.text('Acme Corp'), findsOneWidget);
    });

    testWidgets('has FAB for creating organizations', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
