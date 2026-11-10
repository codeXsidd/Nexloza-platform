import 'package:flutter/material.dart';

enum AlarmSeverity {
  critical('critical', 'Critical', Colors.red),
  high('high', 'High', Colors.deepOrange),
  medium('medium', 'Medium', Colors.orange),
  warning('warning', 'Warning', Colors.amber),
  informational('informational', 'Informational', Colors.blue);

  final String dbValue;
  final String displayName;
  final Color color;

  const AlarmSeverity(this.dbValue, this.displayName, this.color);

  IconData get icon => switch (this) {
        critical => Icons.error,
        high => Icons.warning_amber,
        medium => Icons.info,
        warning => Icons.info_outline,
        informational => Icons.notifications_none,
      };

  int get sortOrder => switch (this) {
        critical => 0,
        high => 1,
        medium => 2,
        warning => 3,
        informational => 4,
      };

  static AlarmSeverity fromString(String value) {
    return AlarmSeverity.values.firstWhere(
      (s) => s.dbValue == value || s.name == value,
      orElse: () => AlarmSeverity.warning,
    );
  }
}
