enum InvitationType {
  organization,
  project;

  static InvitationType fromString(String value) {
    return InvitationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => InvitationType.organization,
    );
  }
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }

  String get displayName => switch (this) {
    pending => 'Pending',
    accepted => 'Accepted',
    declined => 'Declined',
    expired => 'Expired',
    cancelled => 'Cancelled',
  };

  bool get isPending => this == pending;
}

class Invitation {
  final String id;
  final InvitationType type;
  final String? organizationId;
  final String? projectId;
  final String invitedEmail;
  final String? invitedUserId;
  final String invitedBy;
  final String role;
  final InvitationStatus status;
  final String? message;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? organizationName;
  final String? projectName;
  final String? inviterName;

  const Invitation({
    required this.id,
    required this.type,
    this.organizationId,
    this.projectId,
    required this.invitedEmail,
    this.invitedUserId,
    required this.invitedBy,
    required this.role,
    required this.status,
    this.message,
    required this.expiresAt,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.organizationName,
    this.projectName,
    this.inviterName,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    final org = json['organizations'] as Map<String, dynamic>?;
    final project = json['projects'] as Map<String, dynamic>?;
    final inviter = json['inviter:profiles'] as Map<String, dynamic>?;
    return Invitation(
      id: json['id'] as String,
      type: InvitationType.fromString(json['invitation_type'] as String),
      organizationId: json['organization_id'] as String?,
      projectId: json['project_id'] as String?,
      invitedEmail: json['invited_email'] as String,
      invitedUserId: json['invited_user_id'] as String?,
      invitedBy: json['invited_by'] as String,
      role: json['role'] as String,
      status: InvitationStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organizationName: org?['name'] as String?,
      projectName: project?['name'] as String?,
      inviterName: inviter?['full_name'] as String?,
    );
  }

  String get targetName =>
      organizationName ?? projectName ?? organizationId ?? projectId ?? '';

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get canRespond => status.isPending && !isExpired;
}
