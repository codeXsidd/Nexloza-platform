class DataSource {
  final String? projectId;
  final String? deviceId;
  final String? sensorKey;
  final String? actuatorKey;
  final String? telemetryKey;

  const DataSource({
    this.projectId,
    this.deviceId,
    this.sensorKey,
    this.actuatorKey,
    this.telemetryKey,
  });

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      projectId: json['project_id'] as String?,
      deviceId: json['device_id'] as String?,
      sensorKey: json['sensor_key'] as String?,
      actuatorKey: json['actuator_key'] as String?,
      telemetryKey: json['telemetry_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (deviceId != null) 'device_id': deviceId,
    if (sensorKey != null) 'sensor_key': sensorKey,
    if (actuatorKey != null) 'actuator_key': actuatorKey,
    if (telemetryKey != null) 'telemetry_key': telemetryKey,
  };

  bool get hasDevice => deviceId != null && deviceId!.isNotEmpty;
  bool get hasSensor => sensorKey != null && sensorKey!.isNotEmpty;
  bool get hasActuator => actuatorKey != null && actuatorKey!.isNotEmpty;
  bool get isBound => hasDevice && (hasSensor || hasActuator);

  String get effectiveKey => telemetryKey ?? sensorKey ?? actuatorKey ?? '';

  DataSource copyWith({
    String? projectId,
    String? deviceId,
    String? sensorKey,
    String? actuatorKey,
    String? telemetryKey,
  }) {
    return DataSource(
      projectId: projectId ?? this.projectId,
      deviceId: deviceId ?? this.deviceId,
      sensorKey: sensorKey ?? this.sensorKey,
      actuatorKey: actuatorKey ?? this.actuatorKey,
      telemetryKey: telemetryKey ?? this.telemetryKey,
    );
  }
}
