import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/simulation_profile.dart';
import '../domain/entities/simulator_state.dart';

class SimulatorEngine {
  final Map<String, SimulatorDeviceState> _deviceStates = {};
  final Map<String, Timer> _timers = {};
  final Map<String, Random> _randoms = {};
  final Map<String, SimulationProfile> _profiles = {};
  final Map<String, Map<String, double>> _actuatorValues = {};
  final _stateController = StreamController<SimulatorDeviceState>.broadcast();

  Stream<SimulatorDeviceState> get stateStream => _stateController.stream;

  SimulatorDeviceState? getState(String deviceId) => _deviceStates[deviceId];

  void startSimulation({
    required String deviceId,
    required SimulationProfile profile,
    int? seed,
  }) {
    final existing = _deviceStates[deviceId];
    if (existing != null && existing.status == SimulatorStatus.running) return;

    _randoms[deviceId] = seed != null ? Random(seed) : Random();
    _profiles[deviceId] = profile;

    final sensors = <String, SimulatedSensorState>{};
    for (final def in profile.sensors) {
      sensors[def.telemetryKey] = SimulatedSensorState(
        sensorKey: def.telemetryKey,
        currentValue: def.initialValue,
      );
    }

    final actuators = <String, double>{};
    for (final def in profile.actuators) {
      actuators[def.commandKey] = def.initialValue;
    }
    _actuatorValues[deviceId] = actuators;

    final state = SimulatorDeviceState(
      deviceId: deviceId,
      status: SimulatorStatus.running,
      sensors: sensors,
      startedAt: DateTime.now(),
    );
    _deviceStates[deviceId] = state;
    _emitState(deviceId);

    _startTimer(deviceId);
  }

  void pauseSimulation(String deviceId) {
    final state = _deviceStates[deviceId];
    if (state == null || state.status != SimulatorStatus.running) return;

    _timers[deviceId]?.cancel();
    _timers.remove(deviceId);
    _deviceStates[deviceId] = state.copyWith(status: SimulatorStatus.paused);
    _emitState(deviceId);
  }

  void resumeSimulation(String deviceId) {
    final state = _deviceStates[deviceId];
    if (state == null || state.status != SimulatorStatus.paused) return;

    _deviceStates[deviceId] = state.copyWith(status: SimulatorStatus.running);
    _emitState(deviceId);
    _startTimer(deviceId);
  }

  void stopSimulation(String deviceId) {
    _timers[deviceId]?.cancel();
    _timers.remove(deviceId);

    final state = _deviceStates[deviceId];
    if (state == null) return;

    _deviceStates[deviceId] = state.copyWith(status: SimulatorStatus.stopped);
    _emitState(deviceId);
  }

  void resetSimulation(String deviceId) {
    stopSimulation(deviceId);
    final profile = _profiles[deviceId];
    if (profile == null) return;

    final sensors = <String, SimulatedSensorState>{};
    for (final def in profile.sensors) {
      sensors[def.telemetryKey] = SimulatedSensorState(
        sensorKey: def.telemetryKey,
        currentValue: def.initialValue,
      );
    }

    final actuators = <String, double>{};
    for (final def in profile.actuators) {
      actuators[def.commandKey] = def.initialValue;
    }
    _actuatorValues[deviceId] = actuators;

    _deviceStates[deviceId] = SimulatorDeviceState(
      deviceId: deviceId,
      status: SimulatorStatus.idle,
      sensors: sensors,
    );
    _emitState(deviceId);
  }

  void setSpeed(String deviceId, double speed) {
    final state = _deviceStates[deviceId];
    if (state == null) return;

    final clamped = speed.clamp(0.5, 10.0);
    _deviceStates[deviceId] = state.copyWith(speed: clamped);
    _emitState(deviceId);

    if (state.status == SimulatorStatus.running) {
      _timers[deviceId]?.cancel();
      _startTimer(deviceId);
    }
  }

  void setInterval(String deviceId, int intervalMs) {
    final state = _deviceStates[deviceId];
    if (state == null) return;

    final clamped = intervalMs.clamp(1000, 60000);
    _deviceStates[deviceId] = state.copyWith(intervalMs: clamped);
    _emitState(deviceId);

    if (state.status == SimulatorStatus.running) {
      _timers[deviceId]?.cancel();
      _startTimer(deviceId);
    }
  }

  void enableFault(String deviceId, String sensorKey, FaultScenario fault) {
    final state = _deviceStates[deviceId];
    if (state == null) return;

    final sensor = state.sensors[sensorKey];
    if (sensor == null) return;

    final updatedSensors = Map<String, SimulatedSensorState>.from(
      state.sensors,
    );
    updatedSensors[sensorKey] = sensor.copyWith(activeFault: fault);
    _deviceStates[deviceId] = state.copyWith(sensors: updatedSensors);
    _emitState(deviceId);
  }

  void disableFault(String deviceId, String sensorKey) {
    final state = _deviceStates[deviceId];
    if (state == null) return;

    final sensor = state.sensors[sensorKey];
    if (sensor == null) return;

    final updatedSensors = Map<String, SimulatedSensorState>.from(
      state.sensors,
    );
    updatedSensors[sensorKey] = sensor.copyWith(clearFault: true);
    _deviceStates[deviceId] = state.copyWith(sensors: updatedSensors);
    _emitState(deviceId);
  }

  void setSensorEnabled(String deviceId, String sensorKey, bool enabled) {
    final state = _deviceStates[deviceId];
    if (state == null) return;

    final sensor = state.sensors[sensorKey];
    if (sensor == null) return;

    final updatedSensors = Map<String, SimulatedSensorState>.from(
      state.sensors,
    );
    updatedSensors[sensorKey] = sensor.copyWith(isEnabled: enabled);
    _deviceStates[deviceId] = state.copyWith(sensors: updatedSensors);
    _emitState(deviceId);
  }

  void handleActuatorCommand(String deviceId, String commandKey, double value) {
    _actuatorValues[deviceId]?[commandKey] = value;
  }

  Map<String, double> getLatestValues(String deviceId) {
    final state = _deviceStates[deviceId];
    if (state == null) return {};
    return {
      for (final entry in state.sensors.entries)
        entry.key: entry.value.currentValue,
    };
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _stateController.close();
    _timers.clear();
    _deviceStates.clear();
    _randoms.clear();
    _profiles.clear();
    _actuatorValues.clear();
  }

  void _startTimer(String deviceId) {
    final state = _deviceStates[deviceId]!;
    final effectiveInterval = (state.intervalMs / state.speed).round();
    _timers[deviceId] = Timer.periodic(
      Duration(milliseconds: effectiveInterval),
      (_) => _tick(deviceId),
    );
  }

  void _tick(String deviceId) {
    final state = _deviceStates[deviceId];
    if (state == null || state.status != SimulatorStatus.running) return;

    final hasOfflineFault = state.sensors.values.any(
      (s) => s.activeFault == FaultScenario.deviceOffline,
    );
    if (hasOfflineFault) return;

    final rng = _randoms[deviceId] ?? Random();
    final profile = _profiles[deviceId];
    final actuators = _actuatorValues[deviceId] ?? {};
    final updatedSensors = Map<String, SimulatedSensorState>.from(
      state.sensors,
    );
    final now = DateTime.now();

    for (final entry in state.sensors.entries) {
      final key = entry.key;
      final sensor = entry.value;
      if (!sensor.isEnabled) continue;
      if (sensor.activeFault == FaultScenario.sensorFailure) continue;

      final def = profile?.sensors
          .where((s) => s.telemetryKey == key)
          .firstOrNull;
      final minVal = def?.minValue ?? 0;
      final maxVal = def?.maxValue ?? 100;

      double newValue;
      if (sensor.activeFault == FaultScenario.outOfRange) {
        newValue = maxVal + (maxVal - minVal) * 0.2 * rng.nextDouble();
      } else {
        newValue = _computeValue(
          key: key,
          current: sensor.currentValue,
          min: minVal,
          max: maxVal,
          rng: rng,
          actuators: actuators,
        );
      }

      updatedSensors[key] = sensor.copyWith(
        currentValue: newValue,
        lastPublishedAt: now,
      );
    }

    _deviceStates[deviceId] = state.copyWith(sensors: updatedSensors);
    _emitState(deviceId);
  }

  double _computeValue({
    required String key,
    required double current,
    required double min,
    required double max,
    required Random rng,
    required Map<String, double> actuators,
  }) {
    final drift = rng.nextDouble() - 0.5;

    if (key == 'temperature' ||
        key == 'air_temperature' ||
        key == 'motor_temp') {
      final motorOn = (actuators['motor_control'] ?? 0) > 0;
      final fanSpeed = actuators['fan_speed'] ?? 0;
      double delta = drift * 0.3;
      if (key == 'motor_temp' && motorOn) delta += 0.1;
      if (fanSpeed > 0) delta -= fanSpeed / 100 * 0.05;
      return (current + delta).clamp(min, max);
    }

    if (key == 'humidity') {
      return (current + drift * 0.5).clamp(min, max);
    }

    if (key == 'soil_moisture') {
      final pumpActive = (actuators['water_pump'] ?? 0) > 0;
      final delta = pumpActive ? 2.0 : -0.1;
      return (current + delta + drift * 0.3).clamp(min, max);
    }

    if (key == 'tank_level') {
      final pumpOn = (actuators['pump_control'] ?? 0) > 0;
      final valvePos = (actuators['valve_position'] ?? 100) / 100.0;
      final outflow = pumpOn ? 0.5 * valvePos : 0.0;
      final inflow = 0.2;
      return (current + inflow - outflow + drift * 0.1).clamp(min, max);
    }

    if (key == 'vibration') {
      final rpm = actuators.containsKey('motor_speed')
          ? actuators['motor_speed']!
          : current;
      return ((rpm / 3600.0) * 5.0 + rng.nextDouble() * 0.5).clamp(min, max);
    }

    if (key == 'rpm') {
      final motorOn = (actuators['motor_control'] ?? 0) > 0;
      final targetSpeed = actuators['motor_speed'] ?? 0;
      if (!motorOn) {
        return (current * 0.9).clamp(min, max);
      }
      final diff = targetSpeed - current;
      return (current + diff * 0.1 + drift * 10).clamp(min, max);
    }

    if (key == 'voltage') {
      return (230.0 + drift * 2.0).clamp(min, max);
    }

    if (key == 'current') {
      return (current + drift * 0.3).clamp(min, max);
    }

    if (key == 'power') {
      return (current + drift * 20).clamp(min, max);
    }

    if (key == 'power_factor') {
      return (current + drift * 0.01).clamp(min, max);
    }

    if (key == 'energy') {
      return current + (rng.nextDouble() * 0.01);
    }

    if (key == 'motion') {
      return rng.nextDouble() < 0.05 ? 1.0 : 0.0;
    }

    if (key == 'wind_speed') {
      return (current + drift * 2.0).clamp(min, max);
    }

    if (key == 'rainfall') {
      return (current + drift * 0.5).clamp(min, max);
    }

    if (key == 'pressure' || key == 'water_pressure') {
      return (current + drift * 0.2).clamp(min, max);
    }

    if (key == 'flow_rate') {
      final pumpOn = (actuators['pump_control'] ?? 0) > 0;
      final valvePos = (actuators['valve_position'] ?? 100) / 100.0;
      if (!pumpOn) return (current * 0.8).clamp(min, max);
      return (current + drift * 5.0 * valvePos).clamp(min, max);
    }

    if (key == 'leak_detected') {
      return rng.nextDouble() < 0.01 ? 1.0 : 0.0;
    }

    if (key == 'light_level' || key == 'light_intensity') {
      final lightOn = (actuators['light_switch'] ?? 0) > 0;
      final base = lightOn ? max * 0.7 : max * 0.2;
      return (base + drift * max * 0.05).clamp(min, max);
    }

    return (current + drift * (max - min) * 0.02).clamp(min, max);
  }

  void _emitState(String deviceId) {
    final state = _deviceStates[deviceId];
    if (state != null) {
      _stateController.add(state);
    }
  }
}

final simulatorEngineProvider = Provider<SimulatorEngine>((ref) {
  final engine = SimulatorEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});
