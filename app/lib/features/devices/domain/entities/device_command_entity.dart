enum CommandStatus {
  pending,
  sent,
  acknowledged,
  executed,
  failed,
  timeout;

  static CommandStatus fromString(String value) {
    return CommandStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => CommandStatus.pending,
    );
  }

  String get displayName => switch (this) {
    pending => 'Pending',
    sent => 'Sent',
    acknowledged => 'Acknowledged',
    executed => 'Executed',
    failed => 'Failed',
    timeout => 'Timeout',
  };

  bool get isTerminal => this == executed || this == failed || this == timeout;
}

class DeviceCommand {
  final String id;
  final String deviceId;
  final String? issuedBy;
  final String commandType;
  final Map<String, dynamic> payload;
  final CommandStatus status;
  final DateTime? sentAt;
  final DateTime? acknowledgedAt;
  final DateTime? executedAt;
  final DateTime? expiresAt;
  final int retryCount;
  final int maxRetries;
  final String? errorMessage;
  final DateTime createdAt;

  const DeviceCommand({
    required this.id,
    required this.deviceId,
    this.issuedBy,
    required this.commandType,
    this.payload = const {},
    required this.status,
    this.sentAt,
    this.acknowledgedAt,
    this.executedAt,
    this.expiresAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    required this.createdAt,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> json) {
    return DeviceCommand(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      issuedBy: json['issued_by'] as String?,
      commandType: json['command_type'] as String,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      status: CommandStatus.fromString(json['status'] as String),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      executedAt: json['executed_at'] != null
          ? DateTime.parse(json['executed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      retryCount: json['retry_count'] as int? ?? 0,
      maxRetries: json['max_retries'] as int? ?? 3,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
