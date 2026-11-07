enum TriggerType {
  sensorThreshold,
  deviceStateChange,
  schedule,
  time,
  webhook,
  manual,
  deviceOnline,
  deviceOffline;

  String get displayName => switch (this) {
        sensorThreshold => 'Sensor Threshold',
        deviceStateChange => 'Device State Change',
        schedule => 'Schedule',
        time => 'Time',
        webhook => 'Webhook',
        manual => 'Manual',
        deviceOnline => 'Device Online',
        deviceOffline => 'Device Offline',
      };
}

class AutomationTrigger {
  final String id;
  final String automationId;
  final TriggerType triggerType;
  final Map<String, dynamic> config;

  const AutomationTrigger({
    required this.id,
    required this.automationId,
    required this.triggerType,
    required this.config,
  });

  factory AutomationTrigger.fromJson(Map<String, dynamic> json) {
    return AutomationTrigger(
      id: json['id'] as String,
      automationId: json['automation_id'] as String,
      triggerType: TriggerType.values.firstWhere(
        (t) => t.name == json['trigger_type'],
        orElse: () => TriggerType.manual,
      ),
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }
}
