import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/organizations/presentation/providers/organization_provider.dart';

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  const OrganizationDetailScreen({super.key, required this.orgId});
  final String orgId;

  @override
  ConsumerState<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState
    extends ConsumerState<OrganizationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(organizationProvider(widget.orgId));
    final theme = Theme.of(context);

    return orgAsync.when(
      data: (org) {
        if (org == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Organization')),
            body: const Center(child: Text('Organization not found.')),
          );
        }

        final currentUserId = ref.watch(currentUserProvider)?.id;
        final isOwner = org.memberRole == 'owner';
        final isAdmin = org.memberRole == 'admin' || isOwner;

        return Scaffold(
          appBar: AppBar(
            title: Text(org.name),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _showRenameDialog(org.name, org.version),
                ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') _confirmDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(
                          'Delete Organization',
                          style: TextStyle(color: Colors.red),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        org.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(org.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTile(
                icon: Icons.people_rounded,
                title: 'Members',
                subtitle: org.memberCount != null
                    ? '${org.memberCount} member${org.memberCount == 1 ? '' : 's'}'
                    : 'Manage members',
                onTap: () =>
                    context.push('/organizations/${widget.orgId}/members'),
              ),
              _SectionTile(
                icon: Icons.mail_rounded,
                title: 'Invitations',
                subtitle: 'Invite people to this organization',
                onTap: () => context.push('/invitations?orgId=${widget.orgId}'),
              ),
              if (isOwner) ...[
                const SizedBox(height: 24),
                Text(
                  'Danger Zone',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _SectionTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Transfer Ownership',
                  subtitle: 'Transfer to another member',
                  onTap: () => _showTransferDialog(currentUserId),
                  iconColor: theme.colorScheme.error,
                ),
                _SectionTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Organization',
                  subtitle: 'Permanently remove this organization',
                  onTap: _confirmDelete,
                  iconColor: theme.colorScheme.error,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Organization')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Organization')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showRenameDialog(String currentName, int version) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Organization'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            prefixIcon: Icon(Icons.business_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty || name == currentName) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref
                    .read(organizationRepositoryProvider)
                    .updateOrganization(
                      orgId: widget.orgId,
                      expectedVersion: version,
                      name: name,
                    );
                ref.invalidate(organizationProvider(widget.orgId));
                ref.invalidate(organizationsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to rename: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Organization?'),
        content: const Text(
          'This will permanently delete the organization and all its data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(organizationRepositoryProvider)
                    .deleteOrganization(widget.orgId);
                ref.invalidate(organizationsProvider);
                if (mounted) context.go('/organizations');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(String? currentUserId) {
    final members =
        ref.read(organizationMembersProvider(widget.orgId)).valueOrNull ?? [];
    final candidates = members.where((m) => m.userId != currentUserId).toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other members to transfer ownership to.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Ownership'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: candidates.length,
            itemBuilder: (_, i) {
              final m = candidates[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (m.displayName ?? m.userId).substring(0, 1).toUpperCase(),
                  ),
                ),
                title: Text(m.displayName ?? 'Unknown'),
                subtitle: Text(m.role),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(organizationRepositoryProvider)
                        .transferOwnership(widget.orgId, m.userId);
                    ref.invalidate(organizationProvider(widget.orgId));
                    ref.invalidate(organizationMembersProvider(widget.orgId));
                    ref.invalidate(organizationsProvider);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transfer failed: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
