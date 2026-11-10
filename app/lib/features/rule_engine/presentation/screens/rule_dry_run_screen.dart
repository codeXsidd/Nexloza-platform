import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../data/rule_execution_repository.dart';
import '../../domain/entities/rule_execution.dart';

class RuleDryRunScreen extends ConsumerStatefulWidget {
  final String automationId;

  const RuleDryRunScreen({super.key, required this.automationId});

  @override
  ConsumerState<RuleDryRunScreen> createState() => _RuleDryRunScreenState();
}

class _RuleDryRunScreenState extends ConsumerState<RuleDryRunScreen> {
  final _formKey = GlobalKey<FormState>();
  String _eventType = 'telemetry_received';
  final _deviceIdController = TextEditingController();
  final _sensorKeyController = TextEditingController();
  final _valueController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _orgIdController = TextEditingController();

  bool _running = false;
  RuleExecution? _result;
  String? _error;

  static const _eventTypes = [
    'telemetry_received',
    'sensor_value_changed',
    'device_online',
    'device_offline',
    'device_status_changed',
    'twin_reported_changed',
    'twin_desired_changed',
    'manual_trigger',
    'scheduled_trigger',
  ];

  @override
  void dispose() {
    _deviceIdController.dispose();
    _sensorKeyController.dispose();
    _valueController.dispose();
    _projectIdController.dispose();
    _orgIdController.dispose();
    super.dispose();
  }

  Future<void> _runDryTest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _running = true;
      _result = null;
      _error = null;
    });

    final repo = ref.read(ruleExecutionRepositoryProvider);
    dynamic parsedValue;
    final rawValue = _valueController.text.trim();
    if (rawValue.isNotEmpty) {
      parsedValue = double.tryParse(rawValue);
      if (parsedValue == null) {
        if (rawValue.toLowerCase() == 'true') {
          parsedValue = true;
        } else if (rawValue.toLowerCase() == 'false') {
          parsedValue = false;
        } else {
          parsedValue = rawValue;
        }
      }
    }

    final result = await repo.triggerDryRun(
      automationId: widget.automationId,
      projectId: _projectIdController.text.trim(),
      organizationId: _orgIdController.text.trim(),
      eventType: _eventType,
      deviceId: _deviceIdController.text.trim().isEmpty
          ? null
          : _deviceIdController.text.trim(),
      sensorKey: _sensorKeyController.text.trim().isEmpty
          ? null
          : _sensorKeyController.text.trim(),
      value: parsedValue,
    );

    result.when(
      success: (exec) => setState(() {
        _result = exec;
        _running = false;
      }),
      failure: (f) => setState(() {
        _error = f.message;
        _running = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dry Run Test')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulate a rule execution without side effects.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.verticalLg,
              DropdownButtonFormField<String>(
                initialValue: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  prefixIcon: Icon(Icons.bolt),
                ),
                items: _eventTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _projectIdController,
                decoration: const InputDecoration(
                  labelText: 'Project ID',
                  prefixIcon: Icon(Icons.folder),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _orgIdController,
                decoration: const InputDecoration(
                  labelText: 'Organization ID',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID (optional)',
                  prefixIcon: Icon(Icons.memory),
                ),
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _sensorKeyController,
                decoration: const InputDecoration(
                  labelText: 'Sensor Key (optional)',
                  prefixIcon: Icon(Icons.sensors),
                ),
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value (optional)',
                  hintText: 'Number, string, or boolean',
                  prefixIcon: Icon(Icons.data_object),
                ),
              ),
              AppSpacing.verticalLg,
              FilledButton.icon(
                onPressed: _running ? null : _runDryTest,
                icon: _running
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? 'Running...' : 'Run Dry Test'),
              ),
              if (_error != null) ...[
                AppSpacing.verticalLg,
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        Icon(Icons.error, color: theme.colorScheme.error),
                        AppSpacing.horizontalSm,
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_result != null) ...[
                AppSpacing.verticalLg,
                _DryRunResult(execution: _result!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DryRunResult extends StatelessWidget {
  final RuleExecution execution;

  const _DryRunResult({required this.execution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (execution.status) {
      ExecutionStatus.completed => Colors.green,
      ExecutionStatus.failed => Colors.red,
      ExecutionStatus.running => Colors.blue,
      ExecutionStatus.cancelled => Colors.grey,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science, color: theme.colorScheme.primary),
            AppSpacing.horizontalSm,
            Text('Dry Run Result', style: theme.textTheme.titleMedium),
          ],
        ),
        AppSpacing.verticalSm,
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        execution.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DRY RUN',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (execution.durationMs != null)
                      Text(
                        '${execution.durationMs}ms',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
                if (execution.errorMessage != null) ...[
                  AppSpacing.verticalSm,
                  Text(
                    execution.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (execution.nodeResults.isNotEmpty) ...[
          AppSpacing.verticalMd,
          Text('Node Trace', style: theme.textTheme.titleSmall),
          AppSpacing.verticalSm,
          for (final nr in execution.nodeResults) _NodeResultTile(result: nr),
        ],
      ],
    );
  }
}

class _NodeResultTile extends StatelessWidget {
  final NodeResult result;

  const _NodeResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (result.status) {
      'evaluated' => Colors.green,
      'skipped' => Colors.grey,
      'failed' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          result.status == 'evaluated'
              ? Icons.check_circle
              : result.status == 'failed'
              ? Icons.error
              : Icons.skip_next,
          color: color,
          size: 20,
        ),
        title: Text(
          '${result.nodeType} (${result.nodeId})',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: result.error != null
            ? Text(
                result.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
              )
            : result.output != null
            ? Text(
                '${result.output}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              )
            : null,
        trailing: Text(
          result.status,
          style: TextStyle(color: color, fontSize: 11),
        ),
      ),
    );
  }
}
