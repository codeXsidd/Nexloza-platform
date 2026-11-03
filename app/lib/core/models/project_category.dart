class ProjectCategory {
  const ProjectCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final String icon;

  factory ProjectCategory.fromJson(Map<String, dynamic> json) {
    return ProjectCategory(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String? ?? 'devices',
    );
  }
}
