import 'package:flutter/material.dart';

enum WidgetCategory {
  control,
  sensor,
  chart,
  status,
  industrial,
  info;

  String get displayName => switch (this) {
    control => 'Control',
    sensor => 'Sensor',
    chart => 'Chart',
    status => 'Status',
    industrial => 'Industrial',
    info => 'Information',
  };

  IconData get icon => switch (this) {
    control => Icons.touch_app,
    sensor => Icons.sensors,
    chart => Icons.show_chart,
    status => Icons.info_outline,
    industrial => Icons.factory,
    info => Icons.text_fields,
  };
}

enum NexWidgetType {
  // Control widgets
  switchControl('switch', 'Switch', WidgetCategory.control, Icons.toggle_on),
  button('button', 'Button', WidgetCategory.control, Icons.smart_button),
  slider('slider', 'Slider', WidgetCategory.control, Icons.tune),
  numericInput(
    'numeric_input',
    'Numeric Input',
    WidgetCategory.control,
    Icons.pin,
  ),
  dropdown(
    'dropdown',
    'Dropdown',
    WidgetCategory.control,
    Icons.arrow_drop_down,
  ),
  fanSpeed('fan_speed', 'Fan Speed', WidgetCategory.control, Icons.air),
  relayControl(
    'relay_control',
    'Relay Control',
    WidgetCategory.control,
    Icons.power,
  ),
  valveControl(
    'valve_control',
    'Valve Control',
    WidgetCategory.control,
    Icons.water_drop,
  ),

  // Sensor widgets
  temperatureCard(
    'temperature_card',
    'Temperature',
    WidgetCategory.sensor,
    Icons.thermostat,
  ),
  humidityCard(
    'humidity_card',
    'Humidity',
    WidgetCategory.sensor,
    Icons.water_drop,
  ),
  pressureCard('pressure_card', 'Pressure', WidgetCategory.sensor, Icons.speed),
  soilMoistureCard(
    'soil_moisture_card',
    'Soil Moisture',
    WidgetCategory.sensor,
    Icons.grass,
  ),
  waterLevelCard(
    'water_level_card',
    'Water Level',
    WidgetCategory.sensor,
    Icons.waves,
  ),
  lightCard(
    'light_card',
    'Light Intensity',
    WidgetCategory.sensor,
    Icons.wb_sunny,
  ),
  motionCard(
    'motion_card',
    'Motion',
    WidgetCategory.sensor,
    Icons.directions_run,
  ),
  voltageCard('voltage_card', 'Voltage', WidgetCategory.sensor, Icons.bolt),
  powerCard(
    'power_card',
    'Power',
    WidgetCategory.sensor,
    Icons.electrical_services,
  ),
  batteryCard(
    'battery_card',
    'Battery',
    WidgetCategory.sensor,
    Icons.battery_full,
  ),

  // Chart widgets
  lineChart('line_chart', 'Line Chart', WidgetCategory.chart, Icons.show_chart),
  areaChart('area_chart', 'Area Chart', WidgetCategory.chart, Icons.area_chart),
  barChart('bar_chart', 'Bar Chart', WidgetCategory.chart, Icons.bar_chart),
  gauge('gauge', 'Gauge', WidgetCategory.chart, Icons.speed),
  radialGauge(
    'radial_gauge',
    'Radial Gauge',
    WidgetCategory.chart,
    Icons.donut_large,
  ),
  progressBar(
    'progress_bar',
    'Progress Bar',
    WidgetCategory.chart,
    Icons.linear_scale,
  ),
  realtimeChart(
    'realtime_chart',
    'Real-time Chart',
    WidgetCategory.chart,
    Icons.timeline,
  ),
  minMaxAvg(
    'min_max_avg',
    'Min/Max/Avg',
    WidgetCategory.chart,
    Icons.stacked_line_chart,
  ),

  // Status widgets
  deviceStatus(
    'device_status',
    'Device Status',
    WidgetCategory.status,
    Icons.devices_other,
  ),
  mqttStatus('mqtt_status', 'MQTT Status', WidgetCategory.status, Icons.wifi),
  deviceHealth(
    'device_health',
    'Device Health',
    WidgetCategory.status,
    Icons.monitor_heart,
  ),
  alarmIndicator(
    'alarm_indicator',
    'Alarm',
    WidgetCategory.status,
    Icons.warning_amber,
  ),
  commandStatus(
    'command_status',
    'Command Status',
    WidgetCategory.status,
    Icons.send,
  ),
  lastSeen('last_seen', 'Last Seen', WidgetCategory.status, Icons.access_time),
  alarmCount(
    'alarm_count',
    'Alarm Count',
    WidgetCategory.status,
    Icons.notifications_active,
  ),
  criticalAlarmCount(
    'critical_alarm_count',
    'Critical Alarms',
    WidgetCategory.status,
    Icons.error,
  ),
  unacknowledgedAlarmCount(
    'unacknowledged_alarm_count',
    'Unacknowledged',
    WidgetCategory.status,
    Icons.warning,
  ),
  alarmSeverityDistribution(
    'alarm_severity_distribution',
    'Severity Distribution',
    WidgetCategory.status,
    Icons.pie_chart,
  ),
  recentAlarmActivity(
    'recent_alarm_activity',
    'Recent Alarms',
    WidgetCategory.status,
    Icons.history,
  ),

  // Industrial widgets
  machineStatus(
    'machine_status',
    'Machine Status',
    WidgetCategory.industrial,
    Icons.precision_manufacturing,
  ),
  tankLevel('tank_level', 'Tank Level', WidgetCategory.industrial, Icons.water),
  motorStatus(
    'motor_status',
    'Motor Status',
    WidgetCategory.industrial,
    Icons.settings,
  ),
  equipmentStatus(
    'equipment_status',
    'Equipment Status',
    WidgetCategory.industrial,
    Icons.construction,
  ),
  alarmPanel(
    'alarm_panel',
    'Alarm Panel',
    WidgetCategory.industrial,
    Icons.notification_important,
  ),

  // Info widgets
  textWidget('text_widget', 'Text', WidgetCategory.info, Icons.text_fields),
  markdownWidget(
    'markdown_widget',
    'Markdown',
    WidgetCategory.info,
    Icons.article,
  ),
  clockWidget('clock_widget', 'Clock', WidgetCategory.info, Icons.schedule),
  eventLog('event_log', 'Event Log', WidgetCategory.info, Icons.list_alt),
  deviceList(
    'device_list',
    'Device List',
    WidgetCategory.info,
    Icons.device_hub,
  );

  final String typeId;
  final String displayName;
  final WidgetCategory category;
  final IconData icon;

  const NexWidgetType(this.typeId, this.displayName, this.category, this.icon);

  static NexWidgetType fromTypeId(String id) {
    return NexWidgetType.values.firstWhere(
      (t) => t.typeId == id,
      orElse: () => NexWidgetType.textWidget,
    );
  }

  int get defaultWidth => switch (category) {
    WidgetCategory.chart => 2,
    WidgetCategory.industrial => 2,
    WidgetCategory.info when this == deviceList || this == eventLog => 2,
    WidgetCategory.status when this == alarmSeverityDistribution || this == recentAlarmActivity => 2,
    _ => 1,
  };

  int get defaultHeight => switch (category) {
    WidgetCategory.chart => 2,
    WidgetCategory.industrial when this == alarmPanel => 2,
    WidgetCategory.status when this == recentAlarmActivity => 2,
    _ => 1,
  };

  bool get isControl => category == WidgetCategory.control;

  bool get needsDataSource =>
      category != WidgetCategory.info || this == eventLog || this == deviceList;

  static List<NexWidgetType> byCategory(WidgetCategory cat) =>
      values.where((t) => t.category == cat).toList();
}
