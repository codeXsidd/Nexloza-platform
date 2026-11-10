import 'alarm_severity.dart';
import 'alarm_source.dart';
import 'alarm_status.dart';

class Alarm {
  final String id;
  final String alarmKey;
  final String projectId;
  final String? deviceId;
  final String organizationId;
  final AlarmSeverity severity;
  final AlarmStatus status;
  final AlarmSource source;
  final String title;
  final String? message;
  final String category;
  final double? conditionValue;
  final double? thresholdValue;
  final double? hysteresisClearValue;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? clearedBy;
  final DateTime? clearedAt;
  final String? clearedReason;
  final int occurrenceCount;
  final DateTime firstOccurredAt;
  final DateTime lastOccurredAt;
  final Map<String, dynamic> data;
  final String? escalationPolicyId;
  final int? escalationStage;
  final DateTime? escalatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Alarm({
    required this.id,
    required this.alarmKey,
    required this.projectId,
    this.deviceId,
    required this.organizationId,
    required this.severity,
    required this.status,
    required this.source,
    required this.title,
    this.message,
    required this.category,
    this.conditionValue,
    this.thresholdValue,
    this.hysteresisClearValue,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.clearedBy,
    this.clearedAt,
    this.clearedReason,
    required this.occurrenceCount,
    required this.firstOccurredAt,
    required this.lastOccurredAt,
    required this.data,
    this.escalationPolicyId,
    this.escalationStage,
    this.escalatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == AlarmStatus.active;
  bool get isAcknowledged => status == AlarmStatus.acknowledged;
  bool get isCleared => status == AlarmStatus.cleared;
  bool get isCritical => severity == AlarmSeverity.critical;
  bool get isEscalated => escalationPolicyId != null && escalatedAt != null;

  Duration get duration =>
      (clearedAt ?? DateTime.now()).difference(firstOccurredAt);

  static String generateAlarmKey({
    required String source,
    required String projectId,
    String? deviceId,
    String? sensorKey,
    String? category,
  }) {
    final parts = [source, projectId];
    if (deviceId != null) parts.add(deviceId);
    if (sensorKey != null) parts.add(sensorKey);
    if (category != null) parts.add(category);
    return parts.join(':');
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      alarmKey: json['alarm_key'] as String,
      projectId: json['project_id'] as String,
      deviceId: json['device_id'] as String?,
      organizationId: json['organization_id'] as String,
      severity: AlarmSeverity.fromString(
        json['severity'] as String? ?? 'warning',
      ),
      status: AlarmStatus.fromString(json['status'] as String? ?? 'active'),
      source: AlarmSource.fromString(json['source'] as String? ?? 'manual'),
      title: json['title'] as String,
      message: json['message'] as String?,
      category: json['category'] as String? ?? 'general',
      conditionValue: (json['condition_value'] as num?)?.toDouble(),
      thresholdValue: (json['threshold_value'] as num?)?.toDouble(),
      hysteresisClearValue: (json['hysteresis_clear_value'] as num?)
          ?.toDouble(),
      acknowledgedBy: json['acknowledged_by'] as String?,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      clearedBy: json['cleared_by'] as String?,
      clearedAt: json['cleared_at'] != null
          ? DateTime.parse(json['cleared_at'] as String)
          : null,
      clearedReason: json['cleared_reason'] as String?,
      occurrenceCount: json['occurrence_count'] as int? ?? 1,
      firstOccurredAt: DateTime.parse(
        json['first_occurred_at'] as String? ?? json['created_at'] as String,
      ),
      lastOccurredAt: DateTime.parse(
        json['last_occurred_at'] as String? ?? json['created_at'] as String,
      ),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      escalationPolicyId: json['escalation_policy_id'] as String?,
      escalationStage: json['escalation_stage'] as int?,
      escalatedAt: json['escalated_at'] != null
          ? DateTime.parse(json['escalated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alarm_key': alarmKey,
    'project_id': projectId,
    'device_id': deviceId,
    'organization_id': organizationId,
    'severity': severity.dbValue,
    'status': status.dbValue,
    'source': source.dbValue,
    'title': title,
    'message': message,
    'category': category,
    'condition_value': conditionValue,
    'threshold_value': thresholdValue,
    'hysteresis_clear_value': hysteresisClearValue,
    'occurrence_count': occurrenceCount,
    'first_occurred_at': firstOccurredAt.toIso8601String(),
    'last_occurred_at': lastOccurredAt.toIso8601String(),
    'data': data,
    'escalation_policy_id': escalationPolicyId,
  };
}

class AlarmStats {
  final int totalActive;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int warningCount;
  final int informationalCount;
  final int acknowledgedCount;
  final int unacknowledgedCount;

  const AlarmStats({
    required this.totalActive,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.warningCount,
    required this.informationalCount,
    required this.acknowledgedCount,
    required this.unacknowledgedCount,
  });

  factory AlarmStats.empty() => const AlarmStats(
    totalActive: 0,
    criticalCount: 0,
    highCount: 0,
    mediumCount: 0,
    warningCount: 0,
    informationalCount: 0,
    acknowledgedCount: 0,
    unacknowledgedCount: 0,
  );

  factory AlarmStats.fromAlarms(List<Alarm> alarms) {
    final active = alarms.where((a) => a.isActive || a.isAcknowledged).toList();
    return AlarmStats(
      totalActive: active.length,
      criticalCount: active
          .where((a) => a.severity == AlarmSeverity.critical)
          .length,
      highCount: active.where((a) => a.severity == AlarmSeverity.high).length,
      mediumCount: active
          .where((a) => a.severity == AlarmSeverity.medium)
          .length,
      warningCount: active
          .where((a) => a.severity == AlarmSeverity.warning)
          .length,
      informationalCount: active
          .where((a) => a.severity == AlarmSeverity.informational)
          .length,
      acknowledgedCount: active.where((a) => a.isAcknowledged).length,
      unacknowledgedCount: active.where((a) => a.isActive).length,
    );
  }
}
