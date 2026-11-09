import '../../../domain/entities/widget_type.dart';
import '../../../domain/widget_registry.dart';
import 'control_widgets.dart';
import 'sensor_widgets.dart';
import 'chart_widgets.dart';
import 'status_widgets.dart';
import 'industrial_widgets.dart';
import 'info_widgets.dart';

void registerAllWidgets() {
  final registry = WidgetRegistry();

  registry.registerAll([
    // Control (8)
    WidgetRegistration(
      type: NexWidgetType.switchControl,
      builder: buildSwitchControl,
    ),
    WidgetRegistration(type: NexWidgetType.button, builder: buildButton),
    WidgetRegistration(type: NexWidgetType.slider, builder: buildSlider),
    WidgetRegistration(
      type: NexWidgetType.numericInput,
      builder: buildNumericInput,
    ),
    WidgetRegistration(type: NexWidgetType.dropdown, builder: buildDropdown),
    WidgetRegistration(type: NexWidgetType.fanSpeed, builder: buildFanSpeed),
    WidgetRegistration(
      type: NexWidgetType.relayControl,
      builder: buildRelayControl,
    ),
    WidgetRegistration(
      type: NexWidgetType.valveControl,
      builder: buildValveControl,
    ),

    // Sensor (10)
    WidgetRegistration(
      type: NexWidgetType.temperatureCard,
      builder: buildTemperatureCard,
    ),
    WidgetRegistration(
      type: NexWidgetType.humidityCard,
      builder: buildHumidityCard,
    ),
    WidgetRegistration(
      type: NexWidgetType.pressureCard,
      builder: buildPressureCard,
    ),
    WidgetRegistration(
      type: NexWidgetType.soilMoistureCard,
      builder: buildSoilMoistureCard,
    ),
    WidgetRegistration(
      type: NexWidgetType.waterLevelCard,
      builder: buildWaterLevelCard,
    ),
    WidgetRegistration(type: NexWidgetType.lightCard, builder: buildLightCard),
    WidgetRegistration(
      type: NexWidgetType.motionCard,
      builder: buildMotionCard,
    ),
    WidgetRegistration(
      type: NexWidgetType.voltageCard,
      builder: buildVoltageCard,
    ),
    WidgetRegistration(type: NexWidgetType.powerCard, builder: buildPowerCard),
    WidgetRegistration(
      type: NexWidgetType.batteryCard,
      builder: buildBatteryCard,
    ),

    // Chart (8)
    WidgetRegistration(type: NexWidgetType.lineChart, builder: buildLineChart),
    WidgetRegistration(type: NexWidgetType.areaChart, builder: buildAreaChart),
    WidgetRegistration(type: NexWidgetType.barChart, builder: buildBarChart),
    WidgetRegistration(type: NexWidgetType.gauge, builder: buildGauge),
    WidgetRegistration(
      type: NexWidgetType.radialGauge,
      builder: buildRadialGauge,
    ),
    WidgetRegistration(
      type: NexWidgetType.progressBar,
      builder: buildProgressBar,
    ),
    WidgetRegistration(
      type: NexWidgetType.realtimeChart,
      builder: buildRealtimeChart,
    ),
    WidgetRegistration(type: NexWidgetType.minMaxAvg, builder: buildMinMaxAvg),

    // Status (6)
    WidgetRegistration(
      type: NexWidgetType.deviceStatus,
      builder: buildDeviceStatus,
    ),
    WidgetRegistration(
      type: NexWidgetType.mqttStatus,
      builder: buildMqttStatus,
    ),
    WidgetRegistration(
      type: NexWidgetType.deviceHealth,
      builder: buildDeviceHealth,
    ),
    WidgetRegistration(
      type: NexWidgetType.alarmIndicator,
      builder: buildAlarmIndicator,
    ),
    WidgetRegistration(
      type: NexWidgetType.commandStatus,
      builder: buildCommandStatus,
    ),
    WidgetRegistration(type: NexWidgetType.lastSeen, builder: buildLastSeen),

    // Industrial (5)
    WidgetRegistration(
      type: NexWidgetType.machineStatus,
      builder: buildMachineStatus,
    ),
    WidgetRegistration(type: NexWidgetType.tankLevel, builder: buildTankLevel),
    WidgetRegistration(
      type: NexWidgetType.motorStatus,
      builder: buildMotorStatus,
    ),
    WidgetRegistration(
      type: NexWidgetType.equipmentStatus,
      builder: buildEquipmentStatus,
    ),
    WidgetRegistration(
      type: NexWidgetType.alarmPanel,
      builder: buildAlarmPanel,
    ),

    // Info (5)
    WidgetRegistration(
      type: NexWidgetType.textWidget,
      builder: buildTextWidget,
    ),
    WidgetRegistration(
      type: NexWidgetType.markdownWidget,
      builder: buildMarkdownWidget,
    ),
    WidgetRegistration(
      type: NexWidgetType.clockWidget,
      builder: buildClockWidget,
    ),
    WidgetRegistration(type: NexWidgetType.eventLog, builder: buildEventLog),
    WidgetRegistration(
      type: NexWidgetType.deviceList,
      builder: buildDeviceList,
    ),
  ]);
}
