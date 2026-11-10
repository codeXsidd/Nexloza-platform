import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../data/alarm_config_repository.dart';
import '../../domain/entities/alarm_severity.dart';
import '../../domain/entities/alarm_source.dart';

class CreateAlarmConfigScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String organizationId;

  const CreateAlarmConfigScreen({
    super.key,
    required this.projectId,
    required this.organizationId,
  });

  @override
  ConsumerState<CreateAlarmConfigScreen> createState() =>
      _CreateAlarmConfigScreenState();
}

class _CreateAlarmConfigScreenState
    extends ConsumerState<CreateAlarmConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sensorKeyController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _hysteresisClearController = TextEditingController();
  final _debounceController = TextEditingController(text: '0');
  final _cooldownController = TextEditingController(text: '60');
  final _categoryController = TextEditingController(text: 'general');
  final _messageTemplateController = TextEditingController();

  AlarmSource _source = AlarmSource.sensorThreshold;
  String _operator = 'gt';
  AlarmSeverity _severity = AlarmSeverity.warning;
  bool _hysteresisEnabled = false;
  bool _saving = false;

  static const _operators = [
    ('gt', '> Greater than'),
    ('gte', '>= Greater or equal'),
    ('lt', '< Less than'),
    ('lte', '<= Less or equal'),
    ('eq', '= Equal'),
    ('neq', '!= Not equal'),
    ('between', 'Between'),
    ('outside', 'Outside'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _sensorKeyController.dispose();
    _thresholdController.dispose();
    _hysteresisClearController.dispose();
    _debounceController.dispose();
    _cooldownController.dispose();
    _categoryController.dispose();
    _messageTemplateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final repo = ref.read(alarmConfigRepositoryProvider);
    final data = <String, dynamic>{
      'project_id': widget.projectId,
      'organization_id': widget.organizationId,
      'name': _nameController.text.trim(),
      'source': _source.dbValue,
      'condition_operator': _operator,
      'severity': _severity.dbValue,
      'category': _categoryController.text.trim(),
      'hysteresis_enabled': _hysteresisEnabled,
      'debounce_seconds': int.tryParse(_debounceController.text.trim()) ?? 0,
      'cooldown_seconds': int.tryParse(_cooldownController.text.trim()) ?? 60,
      'is_enabled': true,
    };

    if (_sensorKeyController.text.trim().isNotEmpty) {
      data['sensor_key'] = _sensorKeyController.text.trim();
    }
    if (_thresholdController.text.trim().isNotEmpty) {
      data['threshold_value'] =
          double.tryParse(_thresholdController.text.trim());
    }
    if (_hysteresisEnabled &&
        _hysteresisClearController.text.trim().isNotEmpty) {
      data['hysteresis_clear_value'] =
          double.tryParse(_hysteresisClearController.text.trim());
    }
    if (_messageTemplateController.text.trim().isNotEmpty) {
      data['message_template'] = _messageTemplateController.text.trim();
    }

    final result = await repo.createConfiguration(data);

    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm configuration created')),
        );
        Navigator.of(context).pop();
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${f.message}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSensorSource = _source == AlarmSource.sensorThreshold;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Alarm Configuration')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              AppSpacing.verticalMd,
              DropdownButtonFormField<AlarmSource>(
                initialValue: _source,
                decoration: const InputDecoration(
                  labelText: 'Alarm Source',
                  prefixIcon: Icon(Icons.source),
                ),
                items: AlarmSource.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _source = v!),
              ),
              if (isSensorSource) ...[
                AppSpacing.verticalMd,
                TextFormField(
                  controller: _sensorKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Sensor Key',
                    prefixIcon: Icon(Icons.sensors),
                  ),
                  validator: (v) => isSensorSource &&
                          (v == null || v.trim().isEmpty)
                      ? 'Sensor key required for threshold source'
                      : null,
                ),
              ],
              AppSpacing.verticalMd,
              DropdownButtonFormField<String>(
                initialValue: _operator,
                decoration: const InputDecoration(
                  labelText: 'Condition Operator',
                  prefixIcon: Icon(Icons.compare),
                ),
                items: _operators
                    .map((o) => DropdownMenuItem(
                          value: o.$1,
                          child: Text(o.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _operator = v!),
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Threshold Value',
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => isSensorSource &&
                        (v == null || v.trim().isEmpty)
                    ? 'Threshold required for sensor source'
                    : null,
              ),
              AppSpacing.verticalMd,
              SwitchListTile(
                title: const Text('Hysteresis'),
                subtitle:
                    const Text('Use different threshold for clearing alarm'),
                value: _hysteresisEnabled,
                onChanged: (v) => setState(() => _hysteresisEnabled = v),
              ),
              if (_hysteresisEnabled) ...[
                AppSpacing.verticalSm,
                TextFormField(
                  controller: _hysteresisClearController,
                  decoration: const InputDecoration(
                    labelText: 'Hysteresis Clear Value',
                    prefixIcon: Icon(Icons.trending_down),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              AppSpacing.verticalMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _debounceController,
                      decoration: const InputDecoration(
                        labelText: 'Debounce (s)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: TextFormField(
                      controller: _cooldownController,
                      decoration: const InputDecoration(
                        labelText: 'Cooldown (s)',
                        prefixIcon: Icon(Icons.hourglass_bottom),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalMd,
              DropdownButtonFormField<AlarmSeverity>(
                initialValue: _severity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: AlarmSeverity.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(s.icon, color: s.color, size: 18),
                              const SizedBox(width: 8),
                              Text(s.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _severity = v!),
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              AppSpacing.verticalMd,
              TextFormField(
                controller: _messageTemplateController,
                decoration: const InputDecoration(
                  labelText: 'Message Template (optional)',
                  prefixIcon: Icon(Icons.message),
                  hintText:
                      'e.g. Temperature exceeded {threshold} on {device}',
                ),
                maxLines: 3,
              ),
              AppSpacing.verticalLg,
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Create Configuration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
