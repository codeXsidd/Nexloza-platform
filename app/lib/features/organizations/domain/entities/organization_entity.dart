enum OrgRole {
  owner,
  admin,
  member,
  viewer;

  bool get canManage => this == owner || this == admin;
  bool get canEdit => canManage || this == member;
  bool get isOwner => this == owner;

  String get displayName => switch (this) {
    owner => 'Owner',
    admin => 'Admin',
    member => 'Member',
    viewer => 'Viewer',
  };

  static OrgRole fromString(String value) {
    return OrgRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => OrgRole.viewer,
    );
  }
}

class Organization {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String createdBy;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Organization({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdBy,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      createdBy: json['created_by'] as String,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'logo_url': logoUrl,
    'settings': settings,
  };
}

class OrgMember {
  final String id;
  final String organizationId;
  final String userId;
  final OrgRole role;
  final String? invitedBy;
  final DateTime joinedAt;
  final String? userEmail;
  final String? userName;

  const OrgMember({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    this.invitedBy,
    required this.joinedAt,
    this.userEmail,
    this.userName,
  });

  factory OrgMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return OrgMember(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      role: OrgRole.fromString(json['role'] as String),
      invitedBy: json['invited_by'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userEmail: profile?['email'] as String?,
      userName: profile?['full_name'] as String?,
    );
  }

  String get displayName => userName ?? userEmail ?? userId;
}
