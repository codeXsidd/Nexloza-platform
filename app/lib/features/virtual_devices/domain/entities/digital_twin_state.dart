enum TwinSyncStatus {
  synced,
  pending,
  failed,
  stale;

  static TwinSyncStatus fromString(String value) {
    final map = {
      'synced': synced,
      'pending': pending,
      'failed': failed,
      'stale': stale,
    };
    return map[value] ?? synced;
  }

  String get displayName => switch (this) {
    synced => 'Synced',
    pending => 'Pending',
    failed => 'Failed',
    stale => 'Stale',
  };
}

class TwinAttribute {
  final String key;
  final dynamic value;
  final DateTime updatedAt;

  const TwinAttribute({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  factory TwinAttribute.fromJson(Map<String, dynamic> json) {
    return TwinAttribute(
      key: json['key'] as String,
      value: json['value'],
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'updated_at': updatedAt.toIso8601String(),
  };
}

class DigitalTwinState {
  final String id;
  final String deviceId;
  final Map<String, dynamic> reportedState;
  final Map<String, dynamic> desiredState;
  final int reportedVersion;
  final int desiredVersion;
  final DateTime? reportedAt;
  final DateTime? desiredAt;
  final TwinSyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DigitalTwinState({
    required this.id,
    required this.deviceId,
    this.reportedState = const {},
    this.desiredState = const {},
    this.reportedVersion = 0,
    this.desiredVersion = 0,
    this.reportedAt,
    this.desiredAt,
    this.syncStatus = TwinSyncStatus.synced,
    this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DigitalTwinState.fromJson(Map<String, dynamic> json) {
    return DigitalTwinState(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      reportedState: json['reported_state'] as Map<String, dynamic>? ?? {},
      desiredState: json['desired_state'] as Map<String, dynamic>? ?? {},
      reportedVersion: json['reported_version'] as int? ?? 0,
      desiredVersion: json['desired_version'] as int? ?? 0,
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'] as String)
          : null,
      desiredAt: json['desired_at'] != null
          ? DateTime.parse(json['desired_at'] as String)
          : null,
      syncStatus: TwinSyncStatus.fromString(
        json['sync_status'] as String? ?? 'synced',
      ),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'reported_state': reportedState,
    'desired_state': desiredState,
    'reported_version': reportedVersion,
    'desired_version': desiredVersion,
    'reported_at': reportedAt?.toIso8601String(),
    'desired_at': desiredAt?.toIso8601String(),
    'sync_status': syncStatus.name,
    'last_sync_at': lastSyncAt?.toIso8601String(),
  };

  bool get isInSync => syncStatus == TwinSyncStatus.synced;

  List<String> getMismatches() {
    final mismatched = <String>[];
    final allKeys = {...desiredState.keys, ...reportedState.keys};
    for (final key in allKeys) {
      final desired = desiredState[key];
      final reported = reportedState[key];
      if (desired != reported) {
        mismatched.add(key);
      }
    }
    return mismatched;
  }

  DigitalTwinState copyWith({
    String? id,
    String? deviceId,
    Map<String, dynamic>? reportedState,
    Map<String, dynamic>? desiredState,
    int? reportedVersion,
    int? desiredVersion,
    DateTime? reportedAt,
    DateTime? desiredAt,
    TwinSyncStatus? syncStatus,
    DateTime? lastSyncAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DigitalTwinState(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      reportedState: reportedState ?? this.reportedState,
      desiredState: desiredState ?? this.desiredState,
      reportedVersion: reportedVersion ?? this.reportedVersion,
      desiredVersion: desiredVersion ?? this.desiredVersion,
      reportedAt: reportedAt ?? this.reportedAt,
      desiredAt: desiredAt ?? this.desiredAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
