import 'package:flutter/material.dart';

import '../../domain/entities/rule_graph.dart';
import '../../domain/entities/rule_node_type.dart';

class NodeConfigPanel extends StatefulWidget {
  final RuleNode node;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onLabelChanged;

  const NodeConfigPanel({
    super.key,
    required this.node,
    required this.onConfigChanged,
    this.onDelete,
    this.onLabelChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required RuleNode node,
    required ValueChanged<Map<String, dynamic>> onConfigChanged,
    VoidCallback? onDelete,
    ValueChanged<String>? onLabelChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => NodeConfigPanel(
          node: node,
          onConfigChanged: onConfigChanged,
          onDelete: () {
            onDelete?.call();
            Navigator.of(ctx).pop();
          },
          onLabelChanged: onLabelChanged,
        ),
      ),
    );
  }

  @override
  State<NodeConfigPanel> createState() => _NodeConfigPanelState();
}

class _NodeConfigPanelState extends State<NodeConfigPanel> {
  late Map<String, dynamic> _config;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.node.config);
    _labelController = TextEditingController(text: widget.node.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _updateConfig(String key, dynamic value) {
    setState(() => _config[key] = value);
    widget.onConfigChanged(_config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeType = widget.node.type;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              Icon(nodeType.icon, color: nodeType.category.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nodeType.displayName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Node',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            nodeType.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 24),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Node Label',
              hintText: 'Optional display name',
              isDense: true,
            ),
            onChanged: widget.onLabelChanged,
          ),
          const SizedBox(height: 16),
          ..._buildConfigFields(theme),
        ],
      ),
    );
  }

  List<Widget> _buildConfigFields(ThemeData theme) {
    return switch (widget.node.type) {
      RuleNodeType.telemetryReceived ||
      RuleNodeType.deviceOnlineTrigger ||
      RuleNodeType.deviceOfflineTrigger ||
      RuleNodeType.deviceStatusChanged =>
        [_deviceIdField()],
      RuleNodeType.sensorValueChanged => [
          _deviceIdField(),
          _sensorKeyField(),
        ],
      RuleNodeType.sensorAboveThreshold ||
      RuleNodeType.sensorBelowThreshold =>
        [
          _deviceIdField(),
          _sensorKeyField(),
          _thresholdField(),
        ],
      RuleNodeType.twinReportedChanged ||
      RuleNodeType.twinDesiredChanged =>
        [
          _deviceIdField(),
          _attributeKeyField(),
        ],
      RuleNodeType.scheduledTrigger => [_cronField()],
      RuleNodeType.manualTrigger => [
          Text('No configuration needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      RuleNodeType.equalTo ||
      RuleNodeType.notEqualTo ||
      RuleNodeType.greaterThan ||
      RuleNodeType.greaterThanOrEqual ||
      RuleNodeType.lessThan ||
      RuleNodeType.lessThanOrEqual =>
        [_valueField()],
      RuleNodeType.betweenRange => [_minMaxFields()],
      RuleNodeType.booleanCheck => [_boolExpectedField()],
      RuleNodeType.andGate ||
      RuleNodeType.orGate ||
      RuleNodeType.notGate =>
        [
          Text('Connect inputs to evaluate.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      RuleNodeType.deviceOnlineCheck => [_deviceIdField()],
      RuleNodeType.twinDesiredVsReported => [
          _deviceIdField(),
          _attributeKeyField(),
        ],
      RuleNodeType.sendCommand => [
          _deviceIdField(),
          _stringField('command_type', 'Command Type', 'e.g. set_state'),
          _jsonField('payload', 'Payload JSON'),
        ],
      RuleNodeType.setActuator => [
          _deviceIdField(),
          _stringField('actuator_key', 'Actuator Key', 'e.g. fan_speed'),
          _valueField(label: 'Target Value', key: 'value'),
        ],
      RuleNodeType.updateTwinDesired => [
          _deviceIdField(),
          _jsonField('attributes', 'Desired Attributes JSON'),
        ],
      RuleNodeType.executeScene => [
          _stringField('scene_id', 'Scene ID', 'UUID of the scene'),
        ],
      RuleNodeType.recordEvent => [
          _stringField('event_name', 'Event Name', 'e.g. irrigation_blocked'),
          _severityField(),
        ],
      RuleNodeType.logResult => [
          _stringField('message', 'Log Message', 'Message to record'),
        ],
      RuleNodeType.stopFlow || RuleNodeType.terminate => [
          Text('Stops the rule execution.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      RuleNodeType.delay => [_durationField()],
      RuleNodeType.conditionalBranch => [
          Text('Routes execution based on the incoming boolean value.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      RuleNodeType.merge => [
          Text('Merges multiple execution paths.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      RuleNodeType.raiseAlarm => [
          _stringField('alarm_key', 'Alarm Key', 'Unique key for deduplication'),
          _severityField(),
          _stringField('title', 'Alarm Title', 'e.g. Temperature High'),
          _stringField('message', 'Alarm Message', 'Optional detail message'),
          _stringField('category', 'Category', 'e.g. temperature, pressure'),
        ],
      RuleNodeType.updateAlarmSeverity => [
          _stringField('alarm_key', 'Alarm Key', 'Key of alarm to update'),
          _severityField(),
        ],
      RuleNodeType.clearAlarm => [
          _stringField('alarm_key', 'Alarm Key', 'Key of alarm to clear'),
          _stringField('reason', 'Clear Reason', 'Optional reason for clearing'),
        ],
      RuleNodeType.addAlarmComment => [
          _stringField('alarm_key', 'Alarm Key', 'Key of alarm to comment on'),
          _stringField('comment', 'Comment', 'Comment text to add'),
        ],
    };
  }

  Widget _deviceIdField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Device ID',
          hintText: 'UUID of the target device',
          isDense: true,
          prefixIcon: Icon(Icons.memory, size: 20),
        ),
        controller: TextEditingController(text: _config['device_id'] as String? ?? ''),
        onChanged: (v) => _updateConfig('device_id', v),
      ),
    );
  }

  Widget _sensorKeyField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Sensor Key',
          hintText: 'e.g. temperature, humidity',
          isDense: true,
          prefixIcon: Icon(Icons.sensors, size: 20),
        ),
        controller:
            TextEditingController(text: _config['sensor_key'] as String? ?? ''),
        onChanged: (v) => _updateConfig('sensor_key', v),
      ),
    );
  }

  Widget _thresholdField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Threshold',
          hintText: 'Numeric threshold value',
          isDense: true,
          prefixIcon: Icon(Icons.straighten, size: 20),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: TextEditingController(
            text: _config['threshold']?.toString() ?? ''),
        onChanged: (v) {
          final num? parsed = double.tryParse(v);
          if (parsed != null) _updateConfig('threshold', parsed);
        },
      ),
    );
  }

  Widget _attributeKeyField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Attribute Key',
          hintText: 'Twin state attribute key',
          isDense: true,
          prefixIcon: Icon(Icons.vpn_key, size: 20),
        ),
        controller: TextEditingController(
            text: _config['attribute_key'] as String? ?? ''),
        onChanged: (v) => _updateConfig('attribute_key', v),
      ),
    );
  }

  Widget _cronField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Cron Expression',
          hintText: 'e.g. 0 */5 * * * (every 5 min)',
          isDense: true,
          prefixIcon: Icon(Icons.schedule, size: 20),
        ),
        controller: TextEditingController(
            text: _config['cron_expression'] as String? ?? ''),
        onChanged: (v) => _updateConfig('cron_expression', v),
      ),
    );
  }

  Widget _valueField({String label = 'Comparison Value', String key = 'value'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Number, string, or boolean',
          isDense: true,
          prefixIcon: const Icon(Icons.data_object, size: 20),
        ),
        controller:
            TextEditingController(text: _config[key]?.toString() ?? ''),
        onChanged: (v) {
          final num? asNum = double.tryParse(v);
          if (asNum != null) {
            _updateConfig(key, asNum);
          } else if (v.toLowerCase() == 'true') {
            _updateConfig(key, true);
          } else if (v.toLowerCase() == 'false') {
            _updateConfig(key, false);
          } else {
            _updateConfig(key, v);
          }
        },
      ),
    );
  }

  Widget _minMaxFields() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Min Value',
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(
                text: _config['min_value']?.toString() ?? ''),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) _updateConfig('min_value', parsed);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Max Value',
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(
                text: _config['max_value']?.toString() ?? ''),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) _updateConfig('max_value', parsed);
            },
          ),
        ),
      ],
    );
  }

  Widget _boolExpectedField() {
    final expected = _config['expected'] as bool? ?? true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: const Text('Expected Value'),
        subtitle: Text(expected ? 'True' : 'False'),
        value: expected,
        onChanged: (v) => _updateConfig('expected', v),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _severityField() {
    final severity = _config['severity'] as String? ?? 'info';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: severity,
        decoration: const InputDecoration(
          labelText: 'Severity',
          isDense: true,
          prefixIcon: Icon(Icons.warning_amber, size: 20),
        ),
        items: const [
          DropdownMenuItem(value: 'info', child: Text('Info')),
          DropdownMenuItem(value: 'warning', child: Text('Warning')),
          DropdownMenuItem(value: 'error', child: Text('Error')),
          DropdownMenuItem(value: 'critical', child: Text('Critical')),
        ],
        onChanged: (v) => _updateConfig('severity', v ?? 'info'),
      ),
    );
  }

  Widget _durationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Delay (ms)',
          hintText: '1000–3600000',
          isDense: true,
          prefixIcon: Icon(Icons.hourglass_empty, size: 20),
        ),
        keyboardType: TextInputType.number,
        controller: TextEditingController(
            text: _config['duration_ms']?.toString() ?? ''),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) _updateConfig('duration_ms', parsed);
        },
      ),
    );
  }

  Widget _stringField(String key, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
        ),
        controller:
            TextEditingController(text: _config[key] as String? ?? ''),
        onChanged: (v) => _updateConfig(key, v),
      ),
    );
  }

  Widget _jsonField(String key, String label) {
    final current = _config[key];
    final text = current is Map || current is List
        ? current.toString()
        : current?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: '{"key": "value"}',
          isDense: true,
        ),
        maxLines: 3,
        controller: TextEditingController(text: text),
        onChanged: (v) => _updateConfig(key, v),
      ),
    );
  }
}
