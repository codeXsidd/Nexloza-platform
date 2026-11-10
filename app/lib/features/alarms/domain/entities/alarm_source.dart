import 'package:flutter/material.dart';

enum AlarmSource {
  sensorThreshold('sensor_threshold', 'Sensor Threshold', Icons.sensors),
  repeatedTelemetry(
      'repeated_telemetry', 'Repeated Telemetry', Icons.repeat),
  deviceOffline('device_offline', 'Device Offline', Icons.wifi_off),
  staleData('stale_data', 'Stale Data', Icons.schedule),
  twinMismatch('twin_mismatch', 'Twin Mismatch', Icons.compare_arrows),
  actuatorFailure(
      'actuator_failure', 'Actuator Failure', Icons.report_problem),
  virtualDeviceFault(
      'virtual_device_fault', 'Virtual Device Fault', Icons.memory),
  ruleAction('rule_action', 'Rule Action', Icons.account_tree),
  manual('manual', 'Manual', Icons.person);

  final String dbValue;
  final String displayName;
  final IconData icon;

  const AlarmSource(this.dbValue, this.displayName, this.icon);

  static AlarmSource fromString(String value) {
    return AlarmSource.values.firstWhere(
      (s) => s.dbValue == value || s.name == value,
      orElse: () => AlarmSource.manual,
    );
  }
}
