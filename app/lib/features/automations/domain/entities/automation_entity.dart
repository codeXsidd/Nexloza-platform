class Automation {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final bool isEnabled;
  final int priority;
  final int cooldownSeconds;
  final int maxExecutionsPerHour;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Automation({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.isEnabled = true,
    this.priority = 0,
    this.cooldownSeconds = 60,
    this.maxExecutionsPerHour = 60,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Automation.fromJson(Map<String, dynamic> json) {
    return Automation(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      cooldownSeconds: json['cooldown_seconds'] as int? ?? 60,
      maxExecutionsPerHour: json['max_executions_per_hour'] as int? ?? 60,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
