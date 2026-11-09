enum IntegrationType {
  webhook,
  mqtt,
  httpApi,
  slack,
  email,
  telegram,
  custom;

  String get displayName => switch (this) {
    webhook => 'Webhook',
    mqtt => 'MQTT Bridge',
    httpApi => 'HTTP API',
    slack => 'Slack',
    email => 'Email',
    telegram => 'Telegram',
    custom => 'Custom',
  };

  String get iconName => switch (this) {
    webhook => 'webhook',
    mqtt => 'router',
    httpApi => 'api',
    slack => 'chat',
    email => 'email',
    telegram => 'send',
    custom => 'extension',
  };
}

class Integration {
  final String id;
  final String projectId;
  final String name;
  final IntegrationType integrationType;
  final Map<String, dynamic> config;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Integration({
    required this.id,
    required this.projectId,
    required this.name,
    required this.integrationType,
    this.config = const {},
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    return Integration(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      integrationType: IntegrationType.values.firstWhere(
        (t) => t.name == json['integration_type'],
        orElse: () => IntegrationType.custom,
      ),
      config: json['config'] as Map<String, dynamic>? ?? {},
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
