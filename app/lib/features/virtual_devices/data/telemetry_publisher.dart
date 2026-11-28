import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../config/env_config.dart';
import '../../../core/constants/mqtt_constants.dart';
import '../../../core/services/mqtt_service.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../domain/entities/simulator_state.dart';
import 'simulator_engine.dart';

class TelemetryPublisher {
  final SupabaseClient _client;
  final SimulatorEngine _engine;
  final _subscriptions = <String, StreamSubscription<SimulatorDeviceState>>{};
  final _brokers = <String, MqttService>{};
  final _watchers = <String, StreamSubscription<MqttConnectionStatus>>{};
  final _status = StreamController<(String, String)>.broadcast();
  final _messages = <String, String>{};
  bool _disposed = false;
  late final StreamSubscription<AuthState> _auth;

  TelemetryPublisher(this._client, this._engine) {
    var userId = _client.auth.currentUser?.id;
    _auth = _client.auth.onAuthStateChange.listen((event) {
      if (userId == event.session?.user.id) return;
      userId = event.session?.user.id;
      for (final id in {..._subscriptions.keys, ..._brokers.keys}) {
        stopPublishing(id);
        _engine.stopSimulation(id);
      }
      _messages.clear();
    });
  }

  Stream<String> watchDelivery(String deviceId) async* {
    yield _messages[deviceId] ?? 'Telemetry delivery is idle';
    yield* _status.stream
        .where((event) => event.$1 == deviceId)
        .map((event) => event.$2);
  }

  Future<bool> startPublishing({
    required String deviceId,
    required String projectId,
    required String organizationId,
    ({String username, String password})? credentials,
  }) async {
    if (_subscriptions.containsKey(deviceId)) return true;
    if (_brokers.containsKey(deviceId)) return false;

    MqttService? broker;
    if (credentials != null) {
      broker = MqttService();
      _brokers[deviceId] = broker;
      _watchers[deviceId] = broker.statusStream.listen((status) {
        _report(deviceId, 'MQTT: ${status.name}');
      });
      final connected = await broker.connect(
        host: EnvConfig.mqttHost,
        port: EnvConfig.mqttPort,
        clientId: 'sim_${const Uuid().v4().substring(0, 16)}',
        username: credentials.username,
        password: credentials.password,
        useTls: EnvConfig.mqttTls,
      );
      if (!identical(_brokers[deviceId], broker)) return false;
      if (!connected) {
        stopPublishing(deviceId);
        _report(deviceId, 'MQTT connection rejected or unavailable');
        return false;
      }
    }
    _subscriptions[deviceId] = _engine.stateStream
        .where(
          (state) =>
              state.deviceId == deviceId &&
              state.status == SimulatorStatus.running,
        )
        .listen(
          (state) => unawaited(
            _publish(
              state,
              MqttConstants.telemetryTopic(organizationId, projectId, deviceId),
              broker,
            ),
          ),
        );
    return true;
  }

  Future<void> _publish(
    SimulatorDeviceState state,
    String topic,
    MqttService? broker,
  ) async {
    final deviceId = state.deviceId;
    final messageId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final readings = [
      for (final sensor in state.sensors.values)
        if (sensor.isEnabled &&
            sensor.activeFault != FaultScenario.sensorFailure &&
            sensor.activeFault != FaultScenario.deviceOffline &&
            sensor.activeFault != FaultScenario.networkInterrupt)
          {
            'key': sensor.sensorKey,
            'value': sensor.currentValue,
            'timestamp': timestamp,
          },
    ];
    if (readings.isEmpty) return;

    try {
      if (broker != null) {
        final accepted = broker.publish(
          topic,
          jsonEncode({
            'device_id': deviceId,
            'message_id': messageId,
            'readings': readings,
          }),
        );
        _report(
          deviceId,
          accepted
              ? 'Submitted to MQTT · $messageId'
              : 'MQTT disconnected · reading skipped',
        );
        return;
      }
      await _client
          .from('telemetry')
          .upsert(
            [
              for (final reading in readings)
                {
                  'device_id': deviceId,
                  'message_id': messageId,
                  'sensor_key': reading['key'],
                  'value_numeric': reading['value'],
                  'recorded_at': timestamp,
                },
            ],
            onConflict: 'device_id,message_id,sensor_key',
            ignoreDuplicates: true,
          );
      await _client
          .from('devices')
          .update({'last_seen_at': timestamp, 'is_online': true})
          .eq('id', deviceId);
      _report(deviceId, 'Saved to Supabase · $messageId');
    } catch (_) {
      _report(deviceId, 'Telemetry delivery failed · $messageId');
      AppLogger.warning('Simulator telemetry delivery failed');
    }
  }

  void _report(String deviceId, String message) {
    if (_disposed) return;
    _messages[deviceId] = message;
    _status.add((deviceId, message));
  }

  void stopPublishing(String deviceId) {
    unawaited(_subscriptions.remove(deviceId)?.cancel());
    unawaited(_watchers.remove(deviceId)?.cancel());
    _brokers.remove(deviceId)?.dispose();
    _report(deviceId, 'Telemetry delivery is idle');
  }

  void dispose() {
    _disposed = true;
    unawaited(_auth.cancel());
    for (final deviceId in {..._subscriptions.keys, ..._brokers.keys}) {
      stopPublishing(deviceId);
    }
    unawaited(_status.close());
  }
}

final telemetryPublisherProvider = Provider<TelemetryPublisher>((ref) {
  final publisher = TelemetryPublisher(
    ref.watch(supabaseClientProvider),
    ref.watch(simulatorEngineProvider),
  );
  ref.onDispose(publisher.dispose);
  return publisher;
});

final simulatorDeliveryProvider = StreamProvider.autoDispose
    .family<String, String>(
      (ref, deviceId) =>
          ref.watch(telemetryPublisherProvider).watchDelivery(deviceId),
    );
