import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/rule_repository.dart';
import '../../domain/entities/rule_graph.dart';
import '../providers/rule_provider.dart';

class RulesListScreen extends ConsumerWidget {
  final String projectId;

  const RulesListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(rulesProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load rules',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(rulesProvider(projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_tree_outlined,
              title: 'No rules yet',
              subtitle: 'Create your first rule to automate device behavior.',
              actionLabel: 'New Rule',
              onAction: () => context.pushNamed(
                RouteNames.createRule,
                queryParameters: {'projectId': projectId},
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(rulesProvider(projectId)),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: rules.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) =>
                  _RuleCard(rule: rules[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          RouteNames.createRule,
          queryParameters: {'projectId': projectId},
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RuleAutomation rule;

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.ruleDetail,
          pathParameters: {'id': rule.id},
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    color: rule.status.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      rule.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(status: rule.status),
                ],
              ),
              if (rule.description != null &&
                  rule.description!.isNotEmpty) ...[
                AppSpacing.verticalXs,
                Text(
                  rule.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RuleStatus status;

  const _StatusChip({required this.status});

  Color _chipColor() {
    return switch (status) {
      RuleStatus.draft => Colors.grey,
      RuleStatus.validated => Colors.blue,
      RuleStatus.published => Colors.amber,
      RuleStatus.enabled => Colors.green,
      RuleStatus.disabled => Colors.red,
      RuleStatus.archived => Colors.brown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _chipColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
