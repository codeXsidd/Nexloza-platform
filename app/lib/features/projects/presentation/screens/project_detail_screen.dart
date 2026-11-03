import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/organizations/presentation/providers/organization_provider.dart';
import 'package:nexioza/features/projects/presentation/providers/project_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectAsync = ref.watch(projectProvider(projectId));
    final membersAsync = ref.watch(projectMembersProvider(projectId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project')),
            body: const Center(child: Text('Project not found.')),
          );
        }

        final myMember = membersAsync.valueOrNull
            ?.where((m) => m.userId == currentUserId)
            .firstOrNull;
        final canManage = myMember?.canManage ?? false;
        final canEdit = myMember?.canEdit ?? false;

        final color = Color(
          int.parse(project.color.substring(1), radix: 16) + 0xFF000000,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final changed = await context.push<bool>(
                      '/projects/${project.id}/edit',
                    );
                    if (changed == true) {
                      ref.invalidate(projectProvider(projectId));
                      ref.invalidate(projectsProvider);
                    }
                  },
                ),
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'duplicate':
                        _duplicateProject(context, ref, project);
                      case 'delete':
                        _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy_rounded),
                        title: Text('Duplicate'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(
                          'Delete',
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
                        radius: 36,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.folder_rounded,
                          size: 36,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        project.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (project.description != null &&
                          project.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          project.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (project.organizationName != null)
                        Chip(
                          avatar: const Icon(Icons.business_rounded, size: 16),
                          label: Text(project.organizationName!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Members',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No members'),
                    );
                  }
                  return Column(
                    children: members
                        .map(
                          (m) => Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                                backgroundImage: m.avatarUrl != null
                                    ? NetworkImage(m.avatarUrl!)
                                    : null,
                                child: m.avatarUrl == null
                                    ? Text(
                                        (m.displayName ?? '?')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(m.displayName ?? 'Unknown'),
                              subtitle: Text(m.role),
                              trailing: canManage && m.userId != currentUserId
                                  ? PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'remove') {
                                          _removeMember(context, ref, m.userId);
                                        } else {
                                          _updateMemberRole(ref, m.userId, v);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        if (!m.isAdmin && !m.isOwner)
                                          const PopupMenuItem(
                                            value: 'admin',
                                            child: Text('Make Admin'),
                                          ),
                                        if (!m.isEditor && !m.isOwner)
                                          const PopupMenuItem(
                                            value: 'editor',
                                            child: Text('Make Editor'),
                                          ),
                                        if (!m.isViewer)
                                          const PopupMenuItem(
                                            value: 'viewer',
                                            child: Text('Make Viewer'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Version', style: theme.textTheme.labelSmall),
                            Text(
                              '${project.version}',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Members', style: theme.textTheme.labelSmall),
                            Text(
                              '${project.memberCount ?? 0}',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _duplicateProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final nameController = TextEditingController(
      text: '${project.name} (Copy)',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate Project'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Project Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(projectRepositoryProvider)
          .duplicateProject(
            organizationId: project.organizationId,
            source: project,
            name: nameController.text.trim(),
          );
      ref.invalidate(projectsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project duplicated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text(
          'This will permanently delete the project and all its data. '
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
                    .read(projectRepositoryProvider)
                    .deleteProject(projectId);
                ref.invalidate(projectsProvider);
                if (context.mounted) context.pop(true);
              } catch (e) {
                if (context.mounted) {
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

  Future<void> _updateMemberRole(
    WidgetRef ref,
    String targetUserId,
    String newRole,
  ) async {
    try {
      await ref
          .read(organizationRepositoryProvider)
          .updateMemberRole(
            entityType: 'project',
            entityId: projectId,
            targetUserId: targetUserId,
            newRole: newRole,
          );
      ref.invalidate(projectMembersProvider(projectId));
    } catch (_) {}
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Remove this member from the project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(organizationRepositoryProvider)
          .removeMember(
            entityType: 'project',
            entityId: projectId,
            targetUserId: targetUserId,
          );
      ref.invalidate(projectMembersProvider(projectId));
      ref.invalidate(projectProvider(projectId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
