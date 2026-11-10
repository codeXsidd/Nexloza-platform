import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/automation_entity.dart';
import '../providers/automation_provider.dart';

class AutomationsScreen extends ConsumerWidget {
  const AutomationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automationsAsync = ref.watch(automationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.automations),
        actions: [
          TextButton.icon(
            onPressed: () => context.pushNamed(RouteNames.rules),
            icon: const Icon(Icons.account_tree, size: 18),
            label: const Text('Rules'),
          ),
        ],
      ),
      body: automationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load automations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(automationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (automations) {
          if (automations.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.auto_awesome_outlined,
              title: AppStrings.noAutomations,
              subtitle: AppStrings.noAutomationsHint,
              actionLabel: AppStrings.newAutomation,
              onAction: () => context.pushNamed(RouteNames.createAutomation),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(automationsProvider),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: automations.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) =>
                  _AutomationCard(automation: automations[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createAutomation),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newAutomation),
      ),
    );
  }
}

class _AutomationCard extends ConsumerWidget {
  final Automation automation;

  const _AutomationCard({required this.automation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.automationDetail,
          pathParameters: {'id': automation.id},
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: automation.isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      automation.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Switch(
                    value: automation.isEnabled,
                    onChanged: (enabled) {
                      ref
                          .read(automationsProvider.notifier)
                          .toggleAutomation(automation.id, enabled);
                    },
                  ),
                ],
              ),
              if (automation.description != null &&
                  automation.description!.isNotEmpty) ...[
                AppSpacing.verticalXs,
                Text(
                  automation.description!,
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
                    icon: Icons.schedule,
                    label: 'Cooldown: ${automation.cooldownSeconds}s',
                  ),
                  AppSpacing.horizontalSm,
                  _InfoChip(
                    icon: Icons.priority_high,
                    label: 'Priority: ${automation.priority}',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () async {
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: 'Delete Automation',
                        message:
                            'Are you sure you want to delete "${automation.name}"?',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (confirmed) {
                        ref
                            .read(automationsProvider.notifier)
                            .deleteAutomation(automation.id);
                      }
                    },
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
