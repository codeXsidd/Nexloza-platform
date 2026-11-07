class Device {
  final String id;
  final String projectId;
  final String name;
  final String deviceType;
  final HardwarePlatform hardwarePlatform;
  final String? firmwareVersion;
  final String? macAddress;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Device({
    required this.id,
    required this.projectId,
    required this.name,
    required this.deviceType,
    this.hardwarePlatform = HardwarePlatform.esp32,
    this.firmwareVersion,
    this.macAddress,
    this.isOnline = false,
    this.lastSeenAt,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      deviceType: json['device_type'] as String,
      hardwarePlatform: HardwarePlatform.fromString(
        json['hardware_platform'] as String? ?? 'esp32',
      ),
      firmwareVersion: json['firmware_version'] as String?,
      macAddress: json['mac_address'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'name': name,
    'device_type': deviceType,
    'hardware_platform': hardwarePlatform.name,
    'firmware_version': firmwareVersion,
    'mac_address': macAddress,
    'metadata': metadata,
  };
}

enum HardwarePlatform {
  esp32,
  esp8266,
  raspberryPi,
  arduino,
  genericMqtt,
  other;

  static HardwarePlatform fromString(String value) {
    return HardwarePlatform.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HardwarePlatform.other,
    );
  }

  String get displayName => switch (this) {
    esp32 => 'ESP32',
    esp8266 => 'ESP8266',
    raspberryPi => 'Raspberry Pi',
    arduino => 'Arduino',
    genericMqtt => 'Generic MQTT',
    other => 'Other',
  };
}
