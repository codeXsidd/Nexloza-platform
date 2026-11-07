class SensorDefinition {
  final String id;
  final String deviceId;
  final String projectId;
  final String name;
  final String sensorType;
  final String unit;
  final String telemetryKey;
  final int samplingIntervalMs;
  final Map<String, dynamic>? calibration;
  final double? minValue;
  final double? maxValue;
  final double? warningThresholdLow;
  final double? warningThresholdHigh;
  final double? criticalThresholdLow;
  final double? criticalThresholdHigh;
  final bool isActive;
  final DateTime createdAt;

  const SensorDefinition({
    required this.id,
    required this.deviceId,
    required this.projectId,
    required this.name,
    required this.sensorType,
    required this.unit,
    required this.telemetryKey,
    this.samplingIntervalMs = 60000,
    this.calibration,
    this.minValue,
    this.maxValue,
    this.warningThresholdLow,
    this.warningThresholdHigh,
    this.criticalThresholdLow,
    this.criticalThresholdHigh,
    this.isActive = true,
    required this.createdAt,
  });

  factory SensorDefinition.fromJson(Map<String, dynamic> json) {
    return SensorDefinition(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      sensorType: json['sensor_type'] as String,
      unit: json['unit'] as String,
      telemetryKey: json['telemetry_key'] as String,
      samplingIntervalMs: json['sampling_interval_ms'] as int? ?? 60000,
      calibration: json['calibration'] as Map<String, dynamic>?,
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      warningThresholdLow: (json['warning_threshold_low'] as num?)?.toDouble(),
      warningThresholdHigh: (json['warning_threshold_high'] as num?)
          ?.toDouble(),
      criticalThresholdLow: (json['critical_threshold_low'] as num?)
          ?.toDouble(),
      criticalThresholdHigh: (json['critical_threshold_high'] as num?)
          ?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static const List<String> sensorTypes = [
    'temperature',
    'humidity',
    'pressure',
    'gas',
    'smoke',
    'motion',
    'distance',
    'water_level',
    'soil_moisture',
    'light',
    'sound',
    'vibration',
    'current',
    'voltage',
    'energy',
    'gps',
    'air_quality',
    'custom',
  ];
}
