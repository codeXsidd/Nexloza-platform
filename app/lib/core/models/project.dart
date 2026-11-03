class Project {
  const Project({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.categoryId,
    this.icon = 'folder',
    this.color = '#0891B2',
    this.isTemplate = false,
    this.templateId,
    this.metadata,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.memberRole,
    this.memberCount,
    this.organizationName,
  });

  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? categoryId;
  final String icon;
  final String color;
  final bool isTemplate;
  final String? templateId;
  final Map<String, dynamic>? metadata;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? memberRole;
  final int? memberCount;
  final String? organizationName;

  factory Project.fromJson(Map<String, dynamic> json) {
    final members = json['project_members'];
    String? role;
    int? count;
    if (members is List) {
      count = members.length;
      if (members.isNotEmpty) {
        role = members.first['role'] as String?;
      }
    }
    return Project(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      icon: json['icon'] as String? ?? 'folder',
      color: json['color'] as String? ?? '#0891B2',
      isTemplate: json['is_template'] as bool? ?? false,
      templateId: json['template_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberRole: role,
      memberCount: count,
      organizationName:
          (json['organizations'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'name': name,
    'description': description,
    'category_id': categoryId,
    'icon': icon,
    'color': color,
    'is_template': isTemplate,
    'template_id': templateId,
    'metadata': metadata,
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toExport() => {
    'name': name,
    'description': description,
    'category_id': categoryId,
    'icon': icon,
    'color': color,
    'metadata': metadata,
    'export_version': 1,
    'exported_at': DateTime.now().toIso8601String(),
  };

  Project copyWith({
    String? name,
    String? description,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
    int? version,
  }) {
    return Project(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isTemplate: isTemplate,
      templateId: templateId,
      metadata: metadata ?? this.metadata,
      version: version ?? this.version,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      memberRole: memberRole,
      memberCount: memberCount,
      organizationName: organizationName,
    );
  }
}
