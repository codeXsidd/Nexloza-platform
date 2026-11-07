enum ActionType {
  deviceCommand,
  notification,
  email,
  webhook,
  runScene,
  runAutomation,
  aiRecommendation;

  String get displayName => switch (this) {
    deviceCommand => 'Device Command',
    notification => 'Send Notification',
    email => 'Send Email',
    webhook => 'Call Webhook',
    runScene => 'Run Scene',
    runAutomation => 'Run Automation',
    aiRecommendation => 'AI Recommendation',
  };
}

class AutomationAction {
  final String id;
  final String automationId;
  final ActionType actionType;
  final Map<String, dynamic> config;
  final int sortOrder;
  final int delaySeconds;

  const AutomationAction({
    required this.id,
    required this.automationId,
    required this.actionType,
    required this.config,
    this.sortOrder = 0,
    this.delaySeconds = 0,
  });

  factory AutomationAction.fromJson(Map<String, dynamic> json) {
    return AutomationAction(
      id: json['id'] as String,
      automationId: json['automation_id'] as String,
      actionType: ActionType.values.firstWhere(
        (a) => a.name == json['action_type'],
        orElse: () => ActionType.notification,
      ),
      config: json['config'] as Map<String, dynamic>? ?? {},
      sortOrder: json['sort_order'] as int? ?? 0,
      delaySeconds: json['delay_seconds'] as int? ?? 0,
    );
  }
}
