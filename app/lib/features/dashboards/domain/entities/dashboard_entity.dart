class Dashboard {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dashboard({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'name': name,
    'description': description,
    'is_default': isDefault,
  };
}
