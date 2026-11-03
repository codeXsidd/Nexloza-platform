import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/features/invitations/presentation/providers/invitation_provider.dart';
import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invitationsAsync = ref.watch(myInvitationsProvider);
    final invitationCount = invitationsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (invitationCount > 0)
            Card(
              child: ListTile(
                leading: Badge(
                  label: Text('$invitationCount'),
                  child: Icon(
                    Icons.mail_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  '$invitationCount pending invitation${invitationCount == 1 ? '' : 's'}',
                ),
                subtitle: const Text('Tap to view and respond'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/invitations'),
              ),
            ),
          if (invitationCount == 0)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: NexiozaEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'All caught up',
                message: "You'll see device alerts, invitations, and automation events here.",
              ),
            ),
        ],
      ),
    );
  }
}
