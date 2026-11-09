import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../invitations/data/invitation_repository.dart';
import '../providers/organization_provider.dart';

class OrganizationDetailScreen extends ConsumerWidget {
  final String organizationId;

  const OrganizationDetailScreen({super.key, required this.organizationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationDetailProvider(organizationId));
    final membersAsync = ref.watch(orgMembersProvider(organizationId));
    final roleAsync = ref.watch(currentUserOrgRoleProvider(organizationId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: orgAsync.when(
          data: (org) => Text(org?.name ?? 'Organization'),
          loading: () => const Text('Organization'),
          error: (_, __) => const Text('Organization'),
        ),
        actions: [
          roleAsync.when(
            data: (role) {
              if (role?.canManage ?? false) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'invite') {
                      _showInviteDialog(context, ref);
                    } else if (value == 'delete') {
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: 'Delete Organization',
                        message: 'This will permanently delete this organization and remove all members.',
                        isDestructive: true,
                      );
                      if (confirmed && context.mounted) {
                        await ref
                            .read(organizationsProvider.notifier)
                            .deleteOrganization(organizationId);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'invite',
                      child: ListTile(
                        leading: Icon(Icons.person_add_outlined),
                        title: Text('Invite Member'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (role?.isOwner ?? false)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: orgAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(organizationDetailProvider(organizationId));
          },
        ),
        data: (org) {
          if (org == null) {
            return const Center(child: Text('Organization not found'));
          }
          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              if (org.description != null) ...[
                Text(org.description!, style: theme.textTheme.bodyLarge),
                AppSpacing.verticalLg,
              ],
              Text('Members', style: theme.textTheme.titleMedium),
              AppSpacing.verticalSm,
              membersAsync.when(
                loading: () => const LoadingIndicator(),
                error: (error, _) => Text('Error loading members: $error'),
                data: (members) {
                  if (members.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text('No members yet'),
                    );
                  }
                  return Column(
                    children: members.map((member) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Text(
                              member.displayName[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(member.displayName),
                          subtitle: Text(member.role.displayName),
                          trailing: member.role.isOwner
                              ? Chip(
                                  label: const Text('Owner'),
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Member'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'member', child: Text('Member')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedRole = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final repo = ref.read(invitationRepositoryProvider);
                await repo.sendOrganizationInvitation(
                  organizationId: organizationId,
                  email: emailController.text.trim(),
                  role: selectedRole,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation sent')),
                  );
                }
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
