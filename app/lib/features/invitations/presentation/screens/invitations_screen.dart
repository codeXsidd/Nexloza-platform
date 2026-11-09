import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/invitation_entity.dart';
import '../providers/invitation_provider.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(invitationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: invitationsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(invitationsProvider),
        ),
        data: (invitations) {
          if (invitations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.mail_outlined,
              title: 'No Pending Invitations',
              subtitle: 'You don\'t have any pending invitations',
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invite = invitations[index];
              return _InvitationCard(invitation: invite, theme: theme);
            },
          );
        },
      ),
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  final Invitation invitation;
  final ThemeData theme;

  const _InvitationCard({required this.invitation, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOrg = invitation.type == InvitationType.organization;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOrg ? Icons.business_outlined : Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.targetName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${isOrg ? "Organization" : "Project"} invitation',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(invitation.role),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (invitation.message != null) ...[
              AppSpacing.verticalSm,
              Text(invitation.message!, style: theme.textTheme.bodyMedium),
            ],
            if (invitation.inviterName != null) ...[
              AppSpacing.verticalXs,
              Text(
                'Invited by ${invitation.inviterName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AppSpacing.verticalMd,
            if (invitation.canRespond)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final success = await ref
                          .read(invitationsProvider.notifier)
                          .declineInvitation(invitation.id);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation declined')),
                        );
                      }
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () async {
                      final success = await ref
                          .read(invitationsProvider.notifier)
                          .acceptInvitation(invitation.id);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation accepted!')),
                        );
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ],
              )
            else
              Text(
                invitation.isExpired
                    ? 'Expired'
                    : invitation.status.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
