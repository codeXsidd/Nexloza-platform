class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    bool clearAvatar = false,
    int? version,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      version: version ?? this.version,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
