import 'package:flutter/material.dart';

enum AlarmStatus {
  active('active', 'Active', Colors.red),
  acknowledged('acknowledged', 'Acknowledged', Colors.orange),
  cleared('cleared', 'Cleared', Colors.green);

  final String dbValue;
  final String displayName;
  final Color color;

  const AlarmStatus(this.dbValue, this.displayName, this.color);

  IconData get icon => switch (this) {
    active => Icons.error,
    acknowledged => Icons.check_circle_outline,
    cleared => Icons.check_circle,
  };

  static AlarmStatus fromString(String value) {
    return AlarmStatus.values.firstWhere(
      (s) => s.dbValue == value || s.name == value,
      orElse: () => AlarmStatus.active,
    );
  }
}
