class TelemetryReading {
  final int id;
  final String deviceId;
  final String sensorKey;
  final String? messageId;
  final double? valueNumeric;
  final String? valueText;
  final Map<String, dynamic>? valueJson;
  final DateTime recordedAt;
  final DateTime receivedAt;

  const TelemetryReading({
    required this.id,
    required this.deviceId,
    required this.sensorKey,
    this.messageId,
    this.valueNumeric,
    this.valueText,
    this.valueJson,
    required this.recordedAt,
    required this.receivedAt,
  });

  factory TelemetryReading.fromJson(Map<String, dynamic> json) {
    return TelemetryReading(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      sensorKey: json['sensor_key'] as String,
      messageId: json['message_id'] as String?,
      valueNumeric: (json['value_numeric'] as num?)?.toDouble(),
      valueText: json['value_text'] as String?,
      valueJson: json['value_json'] as Map<String, dynamic>?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      receivedAt: DateTime.parse(json['received_at'] as String),
    );
  }

  dynamic get value => valueNumeric ?? valueText ?? valueJson;

  String get displayValue {
    if (valueNumeric != null) {
      return valueNumeric!.toStringAsFixed(
        valueNumeric! == valueNumeric!.roundToDouble() ? 0 : 1,
      );
    }
    if (valueText != null) return valueText!;
    return valueJson?.toString() ?? '--';
  }
}
