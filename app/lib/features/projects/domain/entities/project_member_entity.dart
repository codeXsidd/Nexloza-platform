class ProjectMember {
  final String projectId;
  final String userId;
  final ProjectRole role;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  const ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      role: ProjectRole.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum ProjectRole {
  owner,
  admin,
  developer,
  viewer;

  static ProjectRole fromString(String value) {
    return ProjectRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectRole.viewer,
    );
  }

  bool get canEdit => this == owner || this == admin || this == developer;
  bool get canManage => this == owner || this == admin;
  bool get isOwner => this == owner;
}
