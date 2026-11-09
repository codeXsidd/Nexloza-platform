class DeviceCredential {
  final String id;
  final String deviceId;
  final String apiKey;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  const DeviceCredential({
    required this.id,
    required this.deviceId,
    required this.apiKey,
    this.isActive = true,
    this.expiresAt,
    this.lastUsedAt,
    required this.createdAt,
  });

  factory DeviceCredential.fromJson(Map<String, dynamic> json) {
    return DeviceCredential(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      apiKey: json['api_key'] as String,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class ProvisionedCredential {
  final String apiKey;
  final String apiSecret;
  final DeviceCredential credential;

  const ProvisionedCredential({
    required this.apiKey,
    required this.apiSecret,
    required this.credential,
  });
}
