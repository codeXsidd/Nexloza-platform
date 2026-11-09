import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../core/services/mqtt_service.dart';
import '../../../core/constants/mqtt_constants.dart';
import 'simulator_engine.dart';
import '../domain/entities/simulator_state.dart';

class TelemetryPublisher {
  final SupabaseClient _client;
  final MqttService _mqtt;
  final SimulatorEngine _engine;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, _DeviceTopicInfo> _topicCache = {};

  TelemetryPublisher(this._client, this._mqtt, this._engine);

  Future<void> startPublishing({
    required String deviceId,
    required String projectId,
    required String organizationId,
  }) async {
    if (_subscriptions.containsKey(deviceId)) return;

    _topicCache[deviceId] = _DeviceTopicInfo(
      organizationId: organizationId,
      projectId: projectId,
      deviceId: deviceId,
    );

    _subscriptions[deviceId] = _engine.stateStream
        .where(
          (state) =>
              state.deviceId == deviceId &&
              state.status == SimulatorStatus.running,
        )
        .listen((state) => _publishTelemetry(deviceId, state));
  }

  void stopPublishing(String deviceId) {
    _subscriptions[deviceId]?.cancel();
    _subscriptions.remove(deviceId);
    _topicCache.remove(deviceId);
  }

  Future<void> _publishTelemetry(
    String deviceId,
    SimulatorDeviceState state,
  ) async {
    final topicInfo = _topicCache[deviceId];
    if (topicInfo == null) return;

    final readings = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    for (final entry in state.sensors.entries) {
      final sensor = entry.value;
      if (!sensor.isEnabled) continue;
      if (sensor.activeFault == FaultScenario.sensorFailure) continue;
      if (sensor.activeFault == FaultScenario.deviceOffline) continue;

      readings.add({
        'key': sensor.sensorKey,
        'value': sensor.currentValue,
        'timestamp': now,
      });
    }

    if (readings.isEmpty) return;

    if (_mqtt.status == MqttConnectionStatus.connected) {
      final telemetryTopic = MqttConstants.telemetryTopic(
        topicInfo.organizationId,
        topicInfo.projectId,
        deviceId,
      );
      final payload = jsonEncode({
        'device_id': deviceId,
        'timestamp': now,
        'readings': readings,
      });
      _mqtt.publish(telemetryTopic, payload);
    }

    try {
      final rows = readings.map((r) {
        final value = r['value'];
        return <String, dynamic>{
          'device_id': deviceId,
          'sensor_key': r['key'],
          'value_numeric': value is num ? value.toDouble() : null,
          'value_text': value is String ? value : null,
          'recorded_at': r['timestamp'],
        };
      }).toList();
      await _client.from('telemetry').insert(rows);

      await _client
          .from('devices')
          .update({'last_seen_at': now, 'is_online': true})
          .eq('id', deviceId);
    } catch (_) {}
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _topicCache.clear();
  }
}

class _DeviceTopicInfo {
  final String organizationId;
  final String projectId;
  final String deviceId;

  const _DeviceTopicInfo({
    required this.organizationId,
    required this.projectId,
    required this.deviceId,
  });
}

final telemetryPublisherProvider = Provider<TelemetryPublisher>((ref) {
  final publisher = TelemetryPublisher(
    ref.watch(supabaseClientProvider),
    ref.watch(mqttServiceProvider),
    ref.watch(simulatorEngineProvider),
  );
  ref.onDispose(() => publisher.dispose());
  return publisher;
});
