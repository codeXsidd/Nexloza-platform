import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/core/models/organization_member.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/organizations/presentation/providers/organization_provider.dart';

class OrganizationMembersScreen extends ConsumerWidget {
  const OrganizationMembersScreen({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(organizationMembersProvider(orgId));
    final orgAsync = ref.watch(organizationProvider(orgId));
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final myRole = orgAsync.valueOrNull?.memberRole;
    final isOwner = myRole == 'owner';
    final isAdmin = isOwner || myRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(organizationMembersProvider(orgId)),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) => _MemberTile(
              member: members[index],
              orgId: orgId,
              currentUserId: currentUserId,
              isOwner: isOwner,
              isAdmin: isAdmin,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.orgId,
    required this.currentUserId,
    required this.isOwner,
    required this.isAdmin,
  });

  final OrganizationMember member;
  final String orgId;
  final String? currentUserId;
  final bool isOwner;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSelf = member.userId == currentUserId;
    final canManage = isAdmin && !isSelf && member.role != 'owner';

    final roleColor = switch (member.role) {
      'owner' => theme.colorScheme.primary,
      'admin' => theme.colorScheme.tertiary,
      _ => theme.colorScheme.outline,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            (member.displayName ?? 'U').substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.displayName ?? 'Unknown',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Text(
                '(you)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  member.role,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (_) => [
                  if (isOwner && member.role != 'admin')
                    const PopupMenuItem(
                      value: 'promote',
                      child: ListTile(
                        leading: Icon(Icons.arrow_upward_rounded),
                        title: Text('Promote to Admin'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (isOwner && member.role == 'admin')
                    const PopupMenuItem(
                      value: 'demote',
                      child: ListTile(
                        leading: Icon(Icons.arrow_downward_rounded),
                        title: Text('Demote to Member'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(
                        Icons.person_remove_rounded,
                        color: Colors.red,
                      ),
                      title: Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repo = ref.read(organizationRepositoryProvider);

    try {
      switch (action) {
        case 'promote':
          await repo.updateMemberRole(
            entityType: 'organization',
            entityId: orgId,
            targetUserId: member.userId,
            newRole: 'admin',
          );
        case 'demote':
          await repo.updateMemberRole(
            entityType: 'organization',
            entityId: orgId,
            targetUserId: member.userId,
            newRole: 'member',
          );
        case 'remove':
          final confirmed = await _confirmRemove(context);
          if (!confirmed) return;
          await repo.removeMember(
            entityType: 'organization',
            entityId: orgId,
            targetUserId: member.userId,
          );
      }
      ref.invalidate(organizationMembersProvider(orgId));
      ref.invalidate(organizationProvider(orgId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Remove ${member.displayName ?? 'this member'} from the organization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
