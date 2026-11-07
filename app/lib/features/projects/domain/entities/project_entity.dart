class Project {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? icon;
  final String? organizationId;
  final String ownerId;
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int deviceCount;
  final int onlineDeviceCount;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.icon,
    this.organizationId,
    required this.ownerId,
    this.settings = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deviceCount = 0,
    this.onlineDeviceCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      organizationId: json['organization_id'] as String?,
      ownerId: json['owner_id'] as String,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'icon': icon,
    'organization_id': organizationId,
    'settings': settings,
    'is_active': isActive,
  };

  static const List<String> categories = [
    'Smart Home',
    'Smart Agriculture',
    'Industrial Monitoring',
    'Smart Irrigation',
    'Weather Monitoring',
    'Smart Energy',
    'Water Management',
    'Health & Environment',
    'Security',
    'Custom',
  ];
}
