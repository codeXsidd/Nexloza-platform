enum SimulatorStatus {
  idle,
  running,
  paused,
  stopped;

  static SimulatorStatus fromString(String value) {
    return SimulatorStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SimulatorStatus.idle,
    );
  }

  String get displayName => switch (this) {
    idle => 'Idle',
    running => 'Running',
    paused => 'Paused',
    stopped => 'Stopped',
  };
}

enum FaultScenario {
  deviceOffline,
  sensorFailure,
  outOfRange,
  networkInterrupt,
  commandTimeout;

  static FaultScenario fromString(String value) {
    final map = {
      'device_offline': deviceOffline,
      'sensor_failure': sensorFailure,
      'out_of_range': outOfRange,
      'network_interrupt': networkInterrupt,
      'command_timeout': commandTimeout,
    };
    return map[value] ?? deviceOffline;
  }

  String get dbValue => switch (this) {
    deviceOffline => 'device_offline',
    sensorFailure => 'sensor_failure',
    outOfRange => 'out_of_range',
    networkInterrupt => 'network_interrupt',
    commandTimeout => 'command_timeout',
  };

  String get displayName => switch (this) {
    deviceOffline => 'Device Offline',
    sensorFailure => 'Sensor Failure',
    outOfRange => 'Out of Range',
    networkInterrupt => 'Network Interrupt',
    commandTimeout => 'Command Timeout',
  };

  String get description => switch (this) {
    deviceOffline => 'Simulates the device going completely offline',
    sensorFailure => 'Simulates a sensor that stops reporting data',
    outOfRange => 'Simulates a sensor producing values outside valid bounds',
    networkInterrupt => 'Simulates intermittent network connectivity loss',
    commandTimeout => 'Simulates actuator commands failing to execute',
  };
}

class SimulatedSensorState {
  final String sensorKey;
  final double currentValue;
  final bool isEnabled;
  final FaultScenario? activeFault;
  final DateTime? lastPublishedAt;

  const SimulatedSensorState({
    required this.sensorKey,
    required this.currentValue,
    this.isEnabled = true,
    this.activeFault,
    this.lastPublishedAt,
  });

  SimulatedSensorState copyWith({
    String? sensorKey,
    double? currentValue,
    bool? isEnabled,
    FaultScenario? activeFault,
    bool clearFault = false,
    DateTime? lastPublishedAt,
  }) {
    return SimulatedSensorState(
      sensorKey: sensorKey ?? this.sensorKey,
      currentValue: currentValue ?? this.currentValue,
      isEnabled: isEnabled ?? this.isEnabled,
      activeFault: clearFault ? null : (activeFault ?? this.activeFault),
      lastPublishedAt: lastPublishedAt ?? this.lastPublishedAt,
    );
  }
}

class SimulatorDeviceState {
  final String deviceId;
  final SimulatorStatus status;
  final double speed;
  final int intervalMs;
  final Map<String, SimulatedSensorState> sensors;
  final DateTime? startedAt;
  final String? error;

  const SimulatorDeviceState({
    required this.deviceId,
    this.status = SimulatorStatus.idle,
    this.speed = 1.0,
    this.intervalMs = 5000,
    this.sensors = const {},
    this.startedAt,
    this.error,
  });

  SimulatorDeviceState copyWith({
    String? deviceId,
    SimulatorStatus? status,
    double? speed,
    int? intervalMs,
    Map<String, SimulatedSensorState>? sensors,
    DateTime? startedAt,
    bool clearStartedAt = false,
    String? error,
    bool clearError = false,
  }) {
    return SimulatorDeviceState(
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      intervalMs: intervalMs ?? this.intervalMs,
      sensors: sensors ?? this.sensors,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
