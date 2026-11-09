enum SensorType {
  temperature,
  humidity,
  pressure,
  gas,
  smoke,
  motion,
  ultrasonic,
  waterLevel,
  soilMoisture,
  light,
  sound,
  vibration,
  current,
  voltage,
  energy,
  gps,
  airQuality,
  ph,
  flowRate,
  weight,
  color,
  uv,
  magnetic,
  custom;

  static SensorType fromString(String value) {
    final map = {
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'gas': gas,
      'smoke': smoke,
      'motion': motion,
      'ultrasonic': ultrasonic,
      'water_level': waterLevel,
      'soil_moisture': soilMoisture,
      'light': light,
      'sound': sound,
      'vibration': vibration,
      'current': current,
      'voltage': voltage,
      'energy': energy,
      'gps': gps,
      'air_quality': airQuality,
      'ph': ph,
      'flow_rate': flowRate,
      'weight': weight,
      'color': color,
      'uv': uv,
      'magnetic': magnetic,
      'custom': custom,
    };
    return map[value] ?? custom;
  }

  String get dbValue => switch (this) {
    waterLevel => 'water_level',
    soilMoisture => 'soil_moisture',
    airQuality => 'air_quality',
    flowRate => 'flow_rate',
    _ => name,
  };

  String get displayName => switch (this) {
    temperature => 'Temperature',
    humidity => 'Humidity',
    pressure => 'Pressure',
    gas => 'Gas',
    smoke => 'Smoke',
    motion => 'Motion',
    ultrasonic => 'Ultrasonic',
    waterLevel => 'Water Level',
    soilMoisture => 'Soil Moisture',
    light => 'Light',
    sound => 'Sound',
    vibration => 'Vibration',
    current => 'Current',
    voltage => 'Voltage',
    energy => 'Energy',
    gps => 'GPS',
    airQuality => 'Air Quality',
    ph => 'pH',
    flowRate => 'Flow Rate',
    weight => 'Weight',
    color => 'Color',
    uv => 'UV',
    magnetic => 'Magnetic',
    custom => 'Custom',
  };
}

class SensorDefinition {
  final String id;
  final String deviceId;
  final String projectId;
  final String name;
  final SensorType sensorType;
  final String? unit;
  final String telemetryKey;
  final int samplingIntervalMs;
  final Map<String, dynamic> calibration;
  final double? minValue;
  final double? maxValue;
  final double? warningThresholdLow;
  final double? warningThresholdHigh;
  final double? criticalThresholdLow;
  final double? criticalThresholdHigh;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SensorDefinition({
    required this.id,
    required this.deviceId,
    required this.projectId,
    required this.name,
    required this.sensorType,
    this.unit,
    required this.telemetryKey,
    this.samplingIntervalMs = 60000,
    this.calibration = const {},
    this.minValue,
    this.maxValue,
    this.warningThresholdLow,
    this.warningThresholdHigh,
    this.criticalThresholdLow,
    this.criticalThresholdHigh,
    this.isActive = true,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory SensorDefinition.fromJson(Map<String, dynamic> json) {
    return SensorDefinition(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      sensorType: SensorType.fromString(json['sensor_type'] as String),
      unit: json['unit'] as String?,
      telemetryKey: json['telemetry_key'] as String,
      samplingIntervalMs: json['sampling_interval_ms'] as int? ?? 60000,
      calibration: json['calibration'] as Map<String, dynamic>? ?? {},
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
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'project_id': projectId,
    'name': name,
    'sensor_type': sensorType.dbValue,
    'unit': unit,
    'telemetry_key': telemetryKey,
    'sampling_interval_ms': samplingIntervalMs,
    'calibration': calibration,
    'min_value': minValue,
    'max_value': maxValue,
    'warning_threshold_low': warningThresholdLow,
    'warning_threshold_high': warningThresholdHigh,
    'critical_threshold_low': criticalThresholdLow,
    'critical_threshold_high': criticalThresholdHigh,
    'is_active': isActive,
    'metadata': metadata,
  };
}
