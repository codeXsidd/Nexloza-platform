import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/automation_repository.dart';
import '../../domain/entities/automation_entity.dart';
import '../providers/automation_provider.dart';

final automationDetailProvider = FutureProvider.family<Automation?, String>((
  ref,
  id,
) async {
  final repo = ref.read(automationRepositoryProvider);
  final result = await repo.getAutomations();
  return result.when(
    success: (list) {
      try {
        return list.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    },
    failure: (_) => null,
  );
});

class AutomationDetailScreen extends ConsumerWidget {
  final String automationId;

  const AutomationDetailScreen({super.key, required this.automationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(automationDetailProvider(automationId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: LoadingIndicator(message: 'Loading automation...'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Automation')),
        body: AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(automationDetailProvider(automationId)),
        ),
      ),
      data: (automation) {
        if (automation == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Automation')),
            body: const AppErrorWidget(message: 'Automation not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(automation.name),
            actions: [
              Switch(
                value: automation.isEnabled,
                onChanged: (v) async {
                  await ref
                      .read(automationsProvider.notifier)
                      .toggleAutomation(automation.id, v);
                  ref.invalidate(automationDetailProvider(automationId));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Delete Automation',
                      message:
                          'Delete "${automation.name}"? This cannot be undone.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed && context.mounted) {
                      await ref
                          .read(automationsProvider.notifier)
                          .deleteAutomation(automation.id);
                      if (context.mounted) context.pop();
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(automationDetailProvider(automationId)),
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                _StatusBanner(automation: automation),
                AppSpacing.verticalMd,
                _InfoCard(automation: automation),
                AppSpacing.verticalMd,
                _ConfigCard(automation: automation),
                AppSpacing.verticalMd,
                _DescriptionCard(automation: automation),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Automation automation;

  const _StatusBanner({required this.automation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = automation.isEnabled
        ? Colors.green
        : theme.colorScheme.outline;
    final label = automation.isEnabled ? 'Enabled' : 'Disabled';

    return Card(
      color: color.withAlpha(20),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(
              automation.isEnabled
                  ? Icons.check_circle
                  : Icons.pause_circle_outline,
              color: color,
            ),
            AppSpacing.horizontalMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                Text(
                  'Priority: ${automation.priority}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Automation automation;

  const _InfoCard({required this.automation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            _Row(
              label: 'Created',
              value:
                  '${automation.createdAt.day}/${automation.createdAt.month}/${automation.createdAt.year}',
            ),
            _Row(
              label: 'Updated',
              value:
                  '${automation.updatedAt.day}/${automation.updatedAt.month}/${automation.updatedAt.year}',
            ),
            _Row(
              label: 'Status',
              value: automation.isEnabled ? 'Enabled' : 'Disabled',
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final Automation automation;

  const _ConfigCard({required this.automation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            _Row(
              label: 'Cooldown',
              value: _formatDuration(automation.cooldownSeconds),
            ),
            _Row(
              label: 'Max Executions/hr',
              value: '${automation.maxExecutionsPerHour}',
            ),
            _Row(label: 'Priority', value: '${automation.priority}'),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }
}

class _DescriptionCard extends StatelessWidget {
  final Automation automation;

  const _DescriptionCard({required this.automation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (automation.description == null || automation.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            Text(automation.description!, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
