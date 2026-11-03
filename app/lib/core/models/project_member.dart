class ProjectMember {
  const ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.displayName,
    this.avatarUrl,
    this.email,
  });

  final String projectId;
  final String userId;
  final String role;
  final DateTime createdAt;
  final String? displayName;
  final String? avatarUrl;
  final String? email;

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ProjectMember(
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      email: json['email'] as String?,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';
  bool get canEdit => isOwner || isAdmin || isEditor;
  bool get canManage => isOwner || isAdmin;
}
