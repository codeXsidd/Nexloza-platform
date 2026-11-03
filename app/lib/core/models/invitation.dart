class Invitation {
  const Invitation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.invitedEmail,
    this.invitedBy,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.entityName,
    this.inviterName,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String invitedEmail;
  final String? invitedBy;
  final String role;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? entityName;
  final String? inviterName;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      invitedEmail: json['invited_email'] as String,
      invitedBy: json['invited_by'] as String?,
      role: json['role'] as String,
      status: json['status'] as String? ?? 'pending',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      entityName: json['entity_name'] as String?,
      inviterName: json['inviter_name'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isForOrganization => entityType == 'organization';
  bool get isForProject => entityType == 'project';
}
