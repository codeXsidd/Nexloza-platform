import 'package:flutter/material.dart';

enum SimulationProfileType {
  smartHome,
  agriculture,
  weatherStation,
  energyMonitoring,
  industrialEquipment,
  waterManagement;

  static SimulationProfileType fromString(String value) {
    final map = {
      'smart_home': smartHome,
      'agriculture': agriculture,
      'weather_station': weatherStation,
      'energy_monitoring': energyMonitoring,
      'industrial_equipment': industrialEquipment,
      'water_management': waterManagement,
    };
    return map[value] ?? smartHome;
  }

  String get dbValue => switch (this) {
    smartHome => 'smart_home',
    agriculture => 'agriculture',
    weatherStation => 'weather_station',
    energyMonitoring => 'energy_monitoring',
    industrialEquipment => 'industrial_equipment',
    waterManagement => 'water_management',
  };

  String get displayName => switch (this) {
    smartHome => 'Smart Home',
    agriculture => 'Agriculture',
    weatherStation => 'Weather Station',
    energyMonitoring => 'Energy Monitoring',
    industrialEquipment => 'Industrial Equipment',
    waterManagement => 'Water Management',
  };

  String get description => switch (this) {
    smartHome =>
      'Room temperature, humidity, light, motion, fan and light controls',
    agriculture =>
      'Soil moisture, air temperature, humidity, light, water pump',
    weatherStation => 'Temperature, humidity, pressure, wind speed, rainfall',
    energyMonitoring =>
      'Voltage, current, power, energy consumption, power factor',
    industrialEquipment =>
      'Motor temperature, vibration, RPM, pressure, motor controls',
    waterManagement =>
      'Tank level, flow rate, water pressure, leak detection, pump and valve',
  };

  IconData get icon => switch (this) {
    smartHome => Icons.home,
    agriculture => Icons.grass,
    weatherStation => Icons.cloud,
    energyMonitoring => Icons.bolt,
    industrialEquipment => Icons.precision_manufacturing,
    waterManagement => Icons.water_drop,
  };
}

class SimulatedSensorDef {
  final String name;
  final String sensorType;
  final String telemetryKey;
  final String unit;
  final double minValue;
  final double maxValue;
  final double initialValue;
  final int updateIntervalMs;

  const SimulatedSensorDef({
    required this.name,
    required this.sensorType,
    required this.telemetryKey,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    this.updateIntervalMs = 5000,
  });
}

class SimulatedActuatorDef {
  final String name;
  final String actuatorType;
  final String controlType;
  final String commandKey;
  final double minValue;
  final double maxValue;
  final double step;
  final double initialValue;

  const SimulatedActuatorDef({
    required this.name,
    required this.actuatorType,
    required this.controlType,
    required this.commandKey,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.initialValue,
  });
}

class SimulationProfile {
  final SimulationProfileType profileType;
  final List<SimulatedSensorDef> sensors;
  final List<SimulatedActuatorDef> actuators;

  const SimulationProfile({
    required this.profileType,
    required this.sensors,
    required this.actuators,
  });
}

abstract final class SimulationProfiles {
  static SimulationProfile get smartHome => const SimulationProfile(
    profileType: SimulationProfileType.smartHome,
    sensors: [
      SimulatedSensorDef(
        name: 'Temperature',
        sensorType: 'temperature',
        telemetryKey: 'temperature',
        unit: '°C',
        minValue: 18,
        maxValue: 30,
        initialValue: 22,
      ),
      SimulatedSensorDef(
        name: 'Humidity',
        sensorType: 'humidity',
        telemetryKey: 'humidity',
        unit: '%',
        minValue: 30,
        maxValue: 80,
        initialValue: 55,
      ),
      SimulatedSensorDef(
        name: 'Light Level',
        sensorType: 'light',
        telemetryKey: 'light_level',
        unit: 'lux',
        minValue: 0,
        maxValue: 1000,
        initialValue: 400,
      ),
      SimulatedSensorDef(
        name: 'Motion',
        sensorType: 'motion',
        telemetryKey: 'motion',
        unit: '',
        minValue: 0,
        maxValue: 1,
        initialValue: 0,
      ),
    ],
    actuators: [
      SimulatedActuatorDef(
        name: 'Fan Speed',
        actuatorType: 'fan',
        controlType: 'slider',
        commandKey: 'fan_speed',
        minValue: 0,
        maxValue: 100,
        step: 5,
        initialValue: 0,
      ),
      SimulatedActuatorDef(
        name: 'Light Switch',
        actuatorType: 'light',
        controlType: 'toggle',
        commandKey: 'light_switch',
        minValue: 0,
        maxValue: 1,
        step: 1,
        initialValue: 0,
      ),
    ],
  );

  static SimulationProfile get agriculture => const SimulationProfile(
    profileType: SimulationProfileType.agriculture,
    sensors: [
      SimulatedSensorDef(
        name: 'Soil Moisture',
        sensorType: 'soil_moisture',
        telemetryKey: 'soil_moisture',
        unit: '%',
        minValue: 0,
        maxValue: 100,
        initialValue: 65,
      ),
      SimulatedSensorDef(
        name: 'Air Temperature',
        sensorType: 'temperature',
        telemetryKey: 'air_temperature',
        unit: '°C',
        minValue: 10,
        maxValue: 45,
        initialValue: 28,
      ),
      SimulatedSensorDef(
        name: 'Humidity',
        sensorType: 'humidity',
        telemetryKey: 'humidity',
        unit: '%',
        minValue: 20,
        maxValue: 95,
        initialValue: 60,
      ),
      SimulatedSensorDef(
        name: 'Light Intensity',
        sensorType: 'light',
        telemetryKey: 'light_intensity',
        unit: 'lux',
        minValue: 0,
        maxValue: 120000,
        initialValue: 50000,
      ),
    ],
    actuators: [
      SimulatedActuatorDef(
        name: 'Water Pump',
        actuatorType: 'pump',
        controlType: 'toggle',
        commandKey: 'water_pump',
        minValue: 0,
        maxValue: 1,
        step: 1,
        initialValue: 0,
      ),
    ],
  );

  static SimulationProfile get weatherStation => const SimulationProfile(
    profileType: SimulationProfileType.weatherStation,
    sensors: [
      SimulatedSensorDef(
        name: 'Temperature',
        sensorType: 'temperature',
        telemetryKey: 'temperature',
        unit: '°C',
        minValue: -20,
        maxValue: 50,
        initialValue: 22,
      ),
      SimulatedSensorDef(
        name: 'Humidity',
        sensorType: 'humidity',
        telemetryKey: 'humidity',
        unit: '%',
        minValue: 0,
        maxValue: 100,
        initialValue: 55,
      ),
      SimulatedSensorDef(
        name: 'Atmospheric Pressure',
        sensorType: 'pressure',
        telemetryKey: 'pressure',
        unit: 'hPa',
        minValue: 950,
        maxValue: 1050,
        initialValue: 1013,
      ),
      SimulatedSensorDef(
        name: 'Wind Speed',
        sensorType: 'custom',
        telemetryKey: 'wind_speed',
        unit: 'km/h',
        minValue: 0,
        maxValue: 120,
        initialValue: 10,
      ),
      SimulatedSensorDef(
        name: 'Rainfall',
        sensorType: 'custom',
        telemetryKey: 'rainfall',
        unit: 'mm',
        minValue: 0,
        maxValue: 50,
        initialValue: 0,
      ),
    ],
    actuators: [],
  );

  static SimulationProfile get energyMonitoring => const SimulationProfile(
    profileType: SimulationProfileType.energyMonitoring,
    sensors: [
      SimulatedSensorDef(
        name: 'Voltage',
        sensorType: 'voltage',
        telemetryKey: 'voltage',
        unit: 'V',
        minValue: 200,
        maxValue: 250,
        initialValue: 230,
      ),
      SimulatedSensorDef(
        name: 'Current',
        sensorType: 'current',
        telemetryKey: 'current',
        unit: 'A',
        minValue: 0,
        maxValue: 30,
        initialValue: 5,
      ),
      SimulatedSensorDef(
        name: 'Power',
        sensorType: 'energy',
        telemetryKey: 'power',
        unit: 'W',
        minValue: 0,
        maxValue: 7500,
        initialValue: 1150,
      ),
      SimulatedSensorDef(
        name: 'Energy Consumption',
        sensorType: 'energy',
        telemetryKey: 'energy',
        unit: 'kWh',
        minValue: 0,
        maxValue: 999999,
        initialValue: 1250,
      ),
      SimulatedSensorDef(
        name: 'Power Factor',
        sensorType: 'custom',
        telemetryKey: 'power_factor',
        unit: '',
        minValue: 0.5,
        maxValue: 1.0,
        initialValue: 0.92,
      ),
    ],
    actuators: [],
  );

  static SimulationProfile get industrialEquipment => const SimulationProfile(
    profileType: SimulationProfileType.industrialEquipment,
    sensors: [
      SimulatedSensorDef(
        name: 'Motor Temperature',
        sensorType: 'temperature',
        telemetryKey: 'motor_temp',
        unit: '°C',
        minValue: 20,
        maxValue: 120,
        initialValue: 45,
      ),
      SimulatedSensorDef(
        name: 'Vibration',
        sensorType: 'vibration',
        telemetryKey: 'vibration',
        unit: 'mm/s',
        minValue: 0,
        maxValue: 25,
        initialValue: 2.5,
      ),
      SimulatedSensorDef(
        name: 'RPM',
        sensorType: 'custom',
        telemetryKey: 'rpm',
        unit: 'RPM',
        minValue: 0,
        maxValue: 3600,
        initialValue: 1800,
      ),
      SimulatedSensorDef(
        name: 'Pressure',
        sensorType: 'pressure',
        telemetryKey: 'pressure',
        unit: 'bar',
        minValue: 0,
        maxValue: 10,
        initialValue: 4,
      ),
    ],
    actuators: [
      SimulatedActuatorDef(
        name: 'Motor Control',
        actuatorType: 'motor',
        controlType: 'toggle',
        commandKey: 'motor_control',
        minValue: 0,
        maxValue: 1,
        step: 1,
        initialValue: 0,
      ),
      SimulatedActuatorDef(
        name: 'Motor Speed',
        actuatorType: 'motor',
        controlType: 'slider',
        commandKey: 'motor_speed',
        minValue: 0,
        maxValue: 3600,
        step: 100,
        initialValue: 0,
      ),
    ],
  );

  static SimulationProfile get waterManagement => const SimulationProfile(
    profileType: SimulationProfileType.waterManagement,
    sensors: [
      SimulatedSensorDef(
        name: 'Tank Level',
        sensorType: 'water_level',
        telemetryKey: 'tank_level',
        unit: '%',
        minValue: 0,
        maxValue: 100,
        initialValue: 75,
      ),
      SimulatedSensorDef(
        name: 'Flow Rate',
        sensorType: 'flow_rate',
        telemetryKey: 'flow_rate',
        unit: 'L/min',
        minValue: 0,
        maxValue: 500,
        initialValue: 50,
      ),
      SimulatedSensorDef(
        name: 'Water Pressure',
        sensorType: 'pressure',
        telemetryKey: 'water_pressure',
        unit: 'bar',
        minValue: 0,
        maxValue: 6,
        initialValue: 3,
      ),
      SimulatedSensorDef(
        name: 'Leak Detected',
        sensorType: 'custom',
        telemetryKey: 'leak_detected',
        unit: '',
        minValue: 0,
        maxValue: 1,
        initialValue: 0,
      ),
    ],
    actuators: [
      SimulatedActuatorDef(
        name: 'Pump Control',
        actuatorType: 'pump',
        controlType: 'toggle',
        commandKey: 'pump_control',
        minValue: 0,
        maxValue: 1,
        step: 1,
        initialValue: 0,
      ),
      SimulatedActuatorDef(
        name: 'Valve Position',
        actuatorType: 'valve',
        controlType: 'slider',
        commandKey: 'valve_position',
        minValue: 0,
        maxValue: 100,
        step: 5,
        initialValue: 100,
      ),
    ],
  );

  static SimulationProfile forType(SimulationProfileType type) =>
      switch (type) {
        SimulationProfileType.smartHome => smartHome,
        SimulationProfileType.agriculture => agriculture,
        SimulationProfileType.weatherStation => weatherStation,
        SimulationProfileType.energyMonitoring => energyMonitoring,
        SimulationProfileType.industrialEquipment => industrialEquipment,
        SimulationProfileType.waterManagement => waterManagement,
      };

  static List<SimulationProfile> get all => [
    smartHome,
    agriculture,
    weatherStation,
    energyMonitoring,
    industrialEquipment,
    waterManagement,
  ];
}
