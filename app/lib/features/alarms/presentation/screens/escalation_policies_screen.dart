import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/escalation_repository.dart';
import '../../domain/entities/escalation_policy_entity.dart';
import '../providers/alarm_providers.dart';

class EscalationPoliciesScreen extends ConsumerWidget {
  final String projectId;
  final String organizationId;

  const EscalationPoliciesScreen({
    super.key,
    required this.projectId,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(escalationPoliciesProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Escalation Policies')),
      body: policiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text('Failed to load policies',
                  style: Theme.of(context).textTheme.titleMedium),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(escalationPoliciesProvider(projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (policies) {
          if (policies.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.trending_up,
              title: 'No Escalation Policies',
              subtitle: 'No escalation policies configured for this project',
              actionLabel: 'Create Policy',
              onAction: () => _showCreateDialog(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(escalationPoliciesProvider(projectId)),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: policies.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) =>
                  _PolicyCard(policy: policies[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Policy'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Escalation Policy'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Policy Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final repo = ref.read(escalationRepositoryProvider);
              final result = await repo.createPolicy({
                'project_id': projectId,
                'organization_id': organizationId,
                'name': nameController.text.trim(),
                'description': descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                'is_enabled': true,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              result.when(
                success: (_) {
                  ref.invalidate(escalationPoliciesProvider(projectId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Policy created')),
                  );
                },
                failure: (f) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${f.message}')),
                  );
                },
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final EscalationPolicy policy;

  const _PolicyCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.escalationPolicyDetail,
          pathParameters: {'id': policy.id},
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: policy.isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      policy.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: policy.isEnabled
                          ? Colors.green.withAlpha(30)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      policy.isEnabled ? 'Enabled' : 'Disabled',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: policy.isEnabled
                            ? Colors.green
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              if (policy.description != null &&
                  policy.description!.isNotEmpty) ...[
                AppSpacing.verticalXs,
                Text(
                  policy.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              AppSpacing.verticalSm,
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.layers,
                    label: '${policy.stageCount} stages',
                  ),
                  AppSpacing.horizontalSm,
                  _InfoChip(
                    icon: Icons.schedule,
                    label: '${policy.totalEscalationMinutes}m total',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
