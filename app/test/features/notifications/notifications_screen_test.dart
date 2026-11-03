import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/models/invitation.dart';
import 'package:nexioza/features/invitations/presentation/providers/invitation_provider.dart';
import 'package:nexioza/features/notifications/presentation/screens/notifications_screen.dart';

void main() {
  Widget buildTestWidget({List<Invitation> invitations = const []}) {
    return ProviderScope(
      overrides: [myInvitationsProvider.overrideWith((_) async => invitations)],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  group('NotificationsScreen', () {
    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.text('All caught up'), findsOneWidget);
    });

    testWidgets('shows invitation count when invitations exist', (
      tester,
    ) async {
      final invitations = [
        Invitation(
          id: '1',
          entityType: 'organization',
          entityId: 'org1',
          invitedEmail: 'test@test.com',
          role: 'member',
          status: 'pending',
          expiresAt: DateTime(2030),
          createdAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(buildTestWidget(invitations: invitations));
      await tester.pump();
      expect(find.textContaining('1 pending invitation'), findsOneWidget);
    });
  });
}
