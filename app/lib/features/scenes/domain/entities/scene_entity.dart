class Scene {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  const Scene({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
    required this.createdAt,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static const List<String> presets = [
    'Night Mode',
    'Away Mode',
    'Morning Mode',
    'Security Mode',
    'Energy Saving',
    'Custom',
  ];
}
