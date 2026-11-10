import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/escalation_repository.dart';
import '../../domain/entities/escalation_policy_entity.dart';
import '../providers/alarm_providers.dart';

class EscalationPolicyDetailScreen extends ConsumerStatefulWidget {
  final String policyId;

  const EscalationPolicyDetailScreen({super.key, required this.policyId});

  @override
  ConsumerState<EscalationPolicyDetailScreen> createState() =>
      _EscalationPolicyDetailScreenState();
}

class _EscalationPolicyDetailScreenState
    extends ConsumerState<EscalationPolicyDetailScreen> {
  Future<void> _toggleEnabled(EscalationPolicy policy) async {
    final repo = ref.read(escalationRepositoryProvider);
    await repo.updatePolicy(policy.id, {'is_enabled': !policy.isEnabled});
    ref.invalidate(escalationPolicyDetailProvider(widget.policyId));
  }

  Future<void> _addStage(EscalationPolicy policy) async {
    final delayController = TextEditingController(text: '15');
    final targetsController = TextEditingController();
    String actionType = 'notify';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Escalation Stage'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: delayController,
                  decoration: const InputDecoration(
                    labelText: 'Delay (minutes)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || int.tryParse(v.trim()) == null)
                          ? 'Enter a number'
                          : null,
                ),
                AppSpacing.verticalMd,
                DropdownButtonFormField<String>(
                  initialValue: actionType,
                  decoration: const InputDecoration(
                    labelText: 'Action Type',
                    prefixIcon: Icon(Icons.play_arrow),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'notify', child: Text('Notify')),
                    DropdownMenuItem(
                        value: 'reassign', child: Text('Reassign')),
                    DropdownMenuItem(
                        value: 'auto_acknowledge',
                        child: Text('Auto Acknowledge')),
                  ],
                  onChanged: (v) => setDialogState(() => actionType = v!),
                ),
                AppSpacing.verticalMd,
                TextFormField(
                  controller: targetsController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Target User IDs',
                    helperText: 'Comma-separated UUIDs',
                    prefixIcon: Icon(Icons.people),
                  ),
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
                final targets = targetsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final nextStageNumber = policy.stages.isEmpty
                    ? 1
                    : policy.stages.last.stageNumber + 1;

                final repo = ref.read(escalationRepositoryProvider);
                final result = await repo.addStage({
                  'policy_id': policy.id,
                  'stage_number': nextStageNumber,
                  'delay_minutes':
                      int.tryParse(delayController.text.trim()) ?? 15,
                  'action_type': actionType,
                  'notification_targets': targets,
                });

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                result.when(
                  success: (_) {
                    ref.invalidate(
                        escalationPolicyDetailProvider(widget.policyId));
                  },
                  failure: (f) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${f.message}')),
                    );
                  },
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStage(EscalationStage stage) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Stage',
      message: 'Delete stage ${stage.stageNumber}?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    final repo = ref.read(escalationRepositoryProvider);
    final result = await repo.removeStage(stage.id);
    result.when(
      success: (_) {
        ref.invalidate(escalationPolicyDetailProvider(widget.policyId));
      },
      failure: (f) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${f.message}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final policyAsync =
        ref.watch(escalationPolicyDetailProvider(widget.policyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Escalation Policy')),
      body: policyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text('Failed to load policy',
                  style: theme.textTheme.titleMedium),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(
                    escalationPolicyDetailProvider(widget.policyId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (policy) => SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: theme.colorScheme.primary),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Text(
                              policy.name,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Switch(
                            value: policy.isEnabled,
                            onChanged: (_) => _toggleEnabled(policy),
                          ),
                        ],
                      ),
                      if (policy.description != null &&
                          policy.description!.isNotEmpty) ...[
                        AppSpacing.verticalSm,
                        Text(
                          policy.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      AppSpacing.verticalSm,
                      Row(
                        children: [
                          Icon(Icons.layers,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${policy.stageCount} stages',
                            style: theme.textTheme.bodySmall,
                          ),
                          AppSpacing.horizontalMd,
                          Icon(Icons.schedule,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${policy.totalEscalationMinutes}m total',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalLg,
              Row(
                children: [
                  Text('Stages', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () => _addStage(policy),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Stage'),
                  ),
                ],
              ),
              AppSpacing.verticalSm,
              if (policy.stages.isEmpty)
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Center(
                      child: Text(
                        'No stages configured',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...policy.stages.map(
                  (stage) => _StageCard(
                    stage: stage,
                    onDelete: () => _deleteStage(stage),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final EscalationStage stage;
  final VoidCallback onDelete;

  const _StageCard({required this.stage, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = switch (stage.actionType) {
      'notify' => Colors.blue,
      'reassign' => Colors.orange,
      'auto_acknowledge' => Colors.green,
      _ => theme.colorScheme.outline,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${stage.stageNumber}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${stage.delayMinutes} min delay',
                        style: theme.textTheme.bodyMedium,
                      ),
                      AppSpacing.horizontalSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stage.actionDisplayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: actionColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stage.notificationTargets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${stage.notificationTargets.length} target(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: theme.colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
