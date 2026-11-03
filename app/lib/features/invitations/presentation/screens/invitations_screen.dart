import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/features/invitations/presentation/providers/invitation_provider.dart';
import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invitationsAsync = ref.watch(myInvitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(myInvitationsProvider),
          ),
        ],
      ),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return const NexiozaEmptyState(
              icon: Icons.mail_outline_rounded,
              title: 'No pending invitations',
              message:
                  'Invitations from organizations and projects '
                  'will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myInvitationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final inv = invitations[index];
                final isExpired = inv.isExpired;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              inv.isForOrganization
                                  ? Icons.business_rounded
                                  : Icons.folder_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.entityName ?? 'Unknown',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${inv.entityType.toUpperCase()} • Role: ${inv.role}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isExpired)
                              Chip(
                                label: const Text('Expired'),
                                backgroundColor: theme.colorScheme.error
                                    .withValues(alpha: 0.1),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        if (!isExpired) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _handleReject(context, ref, inv.id),
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () =>
                                    _handleAccept(context, ref, inv.id),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(myInvitationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    String invitationId,
  ) async {
    final tokenController = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Invitation'),
        content: TextField(
          controller: tokenController,
          decoration: const InputDecoration(
            labelText: 'Invitation Token',
            helperText: 'Paste the token from your invitation email',
            prefixIcon: Icon(Icons.key_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, tokenController.text.trim()),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (token == null || token.isEmpty || !context.mounted) return;
    try {
      await ref.read(invitationRepositoryProvider).acceptInvitation(token);
      ref.invalidate(myInvitationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    String invitationId,
  ) async {
    final tokenController = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: TextField(
          controller: tokenController,
          decoration: const InputDecoration(
            labelText: 'Invitation Token',
            helperText: 'Paste the token from your invitation email',
            prefixIcon: Icon(Icons.key_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, tokenController.text.trim()),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (token == null || token.isEmpty || !context.mounted) return;
    try {
      await ref.read(invitationRepositoryProvider).rejectInvitation(token);
      ref.invalidate(myInvitationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
