class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.memberRole,
    this.memberCount,
  });

  final String id;
  final String name;
  final String ownerId;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? memberRole;
  final int? memberCount;

  factory Organization.fromJson(Map<String, dynamic> json) {
    final members = json['organization_members'];
    String? role;
    int? count;
    if (members is List) {
      count = members.length;
      if (members.isNotEmpty) {
        role = members.first['role'] as String?;
      }
    }
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberRole: role,
      memberCount: count,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
