class ActuatorDefinition {
  final String id;
  final String deviceId;
  final String projectId;
  final String name;
  final String actuatorType;
  final ControlType controlType;
  final String telemetryKey;
  final String commandKey;
  final double? minValue;
  final double? maxValue;
  final double? step;
  final Map<String, dynamic>? currentState;
  final bool isActive;
  final DateTime createdAt;

  const ActuatorDefinition({
    required this.id,
    required this.deviceId,
    required this.projectId,
    required this.name,
    required this.actuatorType,
    this.controlType = ControlType.toggle,
    required this.telemetryKey,
    required this.commandKey,
    this.minValue,
    this.maxValue,
    this.step,
    this.currentState,
    this.isActive = true,
    required this.createdAt,
  });

  factory ActuatorDefinition.fromJson(Map<String, dynamic> json) {
    return ActuatorDefinition(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      actuatorType: json['actuator_type'] as String,
      controlType: ControlType.values.firstWhere(
        (c) => c.name == json['control_type'],
        orElse: () => ControlType.toggle,
      ),
      telemetryKey: json['telemetry_key'] as String,
      commandKey: json['command_key'] as String,
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toDouble(),
      currentState: json['current_state'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static const List<String> actuatorTypes = [
    'relay',
    'light',
    'fan',
    'pump',
    'motor',
    'servo',
    'buzzer',
    'switch',
    'smart_plug',
    'custom',
  ];
}

enum ControlType {
  toggle,
  slider,
  numeric,
  multiLevel,
  color;

  String get displayName => switch (this) {
    toggle => 'ON/OFF Toggle',
    slider => 'Slider',
    numeric => 'Numeric Input',
    multiLevel => 'Multi-Level',
    color => 'Color Picker',
  };
}
