import 'package:flutter/material.dart';

import 'alarm_severity.dart';

enum AlarmActivityType {
  created('created', 'Created', Icons.add_circle),
  acknowledged('acknowledged', 'Acknowledged', Icons.check_circle_outline),
  escalated('escalated', 'Escalated', Icons.trending_up),
  cleared('cleared', 'Cleared', Icons.check_circle),
  severityChanged('severity_changed', 'Severity Changed', Icons.swap_vert),
  commentAdded('comment_added', 'Comment Added', Icons.comment),
  suppressed('suppressed', 'Suppressed', Icons.do_not_disturb);

  final String dbValue;
  final String displayName;
  final IconData icon;

  const AlarmActivityType(this.dbValue, this.displayName, this.icon);

  static AlarmActivityType fromString(String value) {
    return AlarmActivityType.values.firstWhere(
      (t) => t.dbValue == value || t.name == value,
      orElse: () => AlarmActivityType.created,
    );
  }
}

class AlarmActivity {
  final String id;
  final String alarmId;
  final AlarmActivityType activityType;
  final String? performedBy;
  final String? comment;
  final AlarmSeverity? previousSeverity;
  final AlarmSeverity? newSeverity;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const AlarmActivity({
    required this.id,
    required this.alarmId,
    required this.activityType,
    this.performedBy,
    this.comment,
    this.previousSeverity,
    this.newSeverity,
    required this.data,
    required this.createdAt,
  });

  factory AlarmActivity.fromJson(Map<String, dynamic> json) {
    return AlarmActivity(
      id: json['id'] as String,
      alarmId: json['alarm_id'] as String,
      activityType: AlarmActivityType.fromString(
        json['activity_type'] as String? ?? 'created',
      ),
      performedBy: json['performed_by'] as String?,
      comment: json['comment'] as String?,
      previousSeverity: json['previous_severity'] != null
          ? AlarmSeverity.fromString(json['previous_severity'] as String)
          : null,
      newSeverity: json['new_severity'] != null
          ? AlarmSeverity.fromString(json['new_severity'] as String)
          : null,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
