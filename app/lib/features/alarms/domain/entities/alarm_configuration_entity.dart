import 'alarm_severity.dart';
import 'alarm_source.dart';

class AlarmConfiguration {
  final String id;
  final String projectId;
  final String? deviceId;
  final String organizationId;
  final String name;
  final AlarmSource source;
  final String? sensorKey;
  final String conditionOperator;
  final double? thresholdValue;
  final bool hysteresisEnabled;
  final double? hysteresisClearValue;
  final int debounceSeconds;
  final int cooldownSeconds;
  final AlarmSeverity severity;
  final String category;
  final String? messageTemplate;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlarmConfiguration({
    required this.id,
    required this.projectId,
    this.deviceId,
    required this.organizationId,
    required this.name,
    required this.source,
    this.sensorKey,
    required this.conditionOperator,
    this.thresholdValue,
    required this.hysteresisEnabled,
    this.hysteresisClearValue,
    required this.debounceSeconds,
    required this.cooldownSeconds,
    required this.severity,
    required this.category,
    this.messageTemplate,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  String get operatorDisplayName => switch (conditionOperator) {
        'gt' => '>',
        'gte' => '>=',
        'lt' => '<',
        'lte' => '<=',
        'eq' => '=',
        'neq' => '!=',
        'between' => 'between',
        'outside' => 'outside',
        _ => conditionOperator,
      };

  factory AlarmConfiguration.fromJson(Map<String, dynamic> json) {
    return AlarmConfiguration(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      deviceId: json['device_id'] as String?,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      source: AlarmSource.fromString(json['source'] as String? ?? 'sensor_threshold'),
      sensorKey: json['sensor_key'] as String?,
      conditionOperator: json['condition_operator'] as String? ?? 'gt',
      thresholdValue: (json['threshold_value'] as num?)?.toDouble(),
      hysteresisEnabled: json['hysteresis_enabled'] as bool? ?? false,
      hysteresisClearValue: (json['hysteresis_clear_value'] as num?)?.toDouble(),
      debounceSeconds: json['debounce_seconds'] as int? ?? 0,
      cooldownSeconds: json['cooldown_seconds'] as int? ?? 60,
      severity: AlarmSeverity.fromString(json['severity'] as String? ?? 'warning'),
      category: json['category'] as String? ?? 'general',
      messageTemplate: json['message_template'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'device_id': deviceId,
        'organization_id': organizationId,
        'name': name,
        'source': source.dbValue,
        'sensor_key': sensorKey,
        'condition_operator': conditionOperator,
        'threshold_value': thresholdValue,
        'hysteresis_enabled': hysteresisEnabled,
        'hysteresis_clear_value': hysteresisClearValue,
        'debounce_seconds': debounceSeconds,
        'cooldown_seconds': cooldownSeconds,
        'severity': severity.dbValue,
        'category': category,
        'message_template': messageTemplate,
        'is_enabled': isEnabled,
      };
}
