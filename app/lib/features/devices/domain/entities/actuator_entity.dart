enum ActuatorType {
  relay,
  light,
  fan,
  pump,
  motor,
  servo,
  buzzer,
  switchType,
  smartPlug,
  valve,
  heater,
  cooler,
  lock,
  rgbLed,
  display,
  custom;

  static ActuatorType fromString(String value) {
    final map = {
      'relay': relay,
      'light': light,
      'fan': fan,
      'pump': pump,
      'motor': motor,
      'servo': servo,
      'buzzer': buzzer,
      'switch': switchType,
      'smart_plug': smartPlug,
      'valve': valve,
      'heater': heater,
      'cooler': cooler,
      'lock': lock,
      'rgb_led': rgbLed,
      'display': display,
      'custom': custom,
    };
    return map[value] ?? custom;
  }

  String get dbValue => switch (this) {
    switchType => 'switch',
    smartPlug => 'smart_plug',
    rgbLed => 'rgb_led',
    _ => name,
  };

  String get displayName => switch (this) {
    relay => 'Relay',
    light => 'Light',
    fan => 'Fan',
    pump => 'Pump',
    motor => 'Motor',
    servo => 'Servo',
    buzzer => 'Buzzer',
    switchType => 'Switch',
    smartPlug => 'Smart Plug',
    valve => 'Valve',
    heater => 'Heater',
    cooler => 'Cooler',
    lock => 'Lock',
    rgbLed => 'RGB LED',
    display => 'Display',
    custom => 'Custom',
  };
}

enum ControlType {
  toggle,
  slider,
  numeric,
  multiLevel,
  color,
  custom;

  static ControlType fromString(String value) {
    final map = {
      'toggle': toggle,
      'slider': slider,
      'numeric': numeric,
      'multi_level': multiLevel,
      'color': color,
      'custom': custom,
    };
    return map[value] ?? toggle;
  }

  String get dbValue => switch (this) {
    multiLevel => 'multi_level',
    _ => name,
  };

  String get displayName => switch (this) {
    toggle => 'Toggle',
    slider => 'Slider',
    numeric => 'Numeric',
    multiLevel => 'Multi Level',
    color => 'Color',
    custom => 'Custom',
  };
}

class ActuatorDefinition {
  final String id;
  final String deviceId;
  final String projectId;
  final String name;
  final ActuatorType actuatorType;
  final ControlType controlType;
  final String? telemetryKey;
  final String commandKey;
  final double minValue;
  final double maxValue;
  final double step;
  final Map<String, dynamic> currentState;
  final Map<String, dynamic> safetyLimits;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActuatorDefinition({
    required this.id,
    required this.deviceId,
    required this.projectId,
    required this.name,
    required this.actuatorType,
    this.controlType = ControlType.toggle,
    this.telemetryKey,
    required this.commandKey,
    this.minValue = 0,
    this.maxValue = 1,
    this.step = 1,
    this.currentState = const {},
    this.safetyLimits = const {},
    this.isActive = true,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActuatorDefinition.fromJson(Map<String, dynamic> json) {
    return ActuatorDefinition(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      actuatorType: ActuatorType.fromString(json['actuator_type'] as String),
      controlType: ControlType.fromString(json['control_type'] as String),
      telemetryKey: json['telemetry_key'] as String?,
      commandKey: json['command_key'] as String,
      minValue: (json['min_value'] as num?)?.toDouble() ?? 0,
      maxValue: (json['max_value'] as num?)?.toDouble() ?? 1,
      step: (json['step'] as num?)?.toDouble() ?? 1,
      currentState: json['current_state'] as Map<String, dynamic>? ?? {},
      safetyLimits: json['safety_limits'] as Map<String, dynamic>? ?? {},
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
    'actuator_type': actuatorType.dbValue,
    'control_type': controlType.dbValue,
    'telemetry_key': telemetryKey,
    'command_key': commandKey,
    'min_value': minValue,
    'max_value': maxValue,
    'step': step,
    'current_state': currentState,
    'safety_limits': safetyLimits,
    'is_active': isActive,
    'metadata': metadata,
  };

  bool get isOn => currentState['is_on'] as bool? ?? false;
  double get currentValue => (currentState['value'] as num?)?.toDouble() ?? 0;
}
