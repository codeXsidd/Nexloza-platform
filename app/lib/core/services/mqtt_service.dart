import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../constants/mqtt_constants.dart';
import '../utils/logger.dart';

enum MqttConnectionStatus { disconnected, connecting, connected, error }

class NexlozaMqttMessage {
  final String topic;
  final String payload;
  final DateTime receivedAt;

  const NexlozaMqttMessage({
    required this.topic,
    required this.payload,
    required this.receivedAt,
  });
}

class MqttService {
  MqttServerClient? _client;
  final _statusController = StreamController<MqttConnectionStatus>.broadcast();
  final _messageController = StreamController<NexlozaMqttMessage>.broadcast();
  MqttConnectionStatus _status = MqttConnectionStatus.disconnected;

  Stream<MqttConnectionStatus> get statusStream => _statusController.stream;
  Stream<NexlozaMqttMessage> get messageStream => _messageController.stream;
  MqttConnectionStatus get status => _status;

  Future<bool> connect({
    required String host,
    required int port,
    required String clientId,
    String? username,
    String? password,
    bool useTls = false,
  }) async {
    if (_status == MqttConnectionStatus.connected) return true;

    _updateStatus(MqttConnectionStatus.connecting);

    _client = MqttServerClient(host, clientId)
      ..port = port
      ..keepAlivePeriod = MqttConstants.keepAliveSeconds
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected;

    if (useTls) {
      _client!.secure = true;
    }

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (username != null && password != null) {
      _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
    }

    try {
      await _client!.connect(username, password);
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _setupMessageListener();
        return true;
      }
      _updateStatus(MqttConnectionStatus.error);
      return false;
    } catch (e) {
      AppLogger.error('MQTT connection failed', error: e);
      _updateStatus(MqttConnectionStatus.error);
      _client?.disconnect();
      return false;
    }
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      AppLogger.warning('Cannot subscribe: not connected');
      return;
    }
    _client!.subscribe(topic, qos);
    AppLogger.info('Subscribed to: $topic');
  }

  void unsubscribe(String topic) {
    _client?.unsubscribe(topic);
  }

  void publish(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      AppLogger.warning('Cannot publish: not connected');
      return;
    }
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    _updateStatus(MqttConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }

  String buildTopic({
    required String organizationId,
    required String projectId,
    required String deviceId,
    required String channel,
  }) {
    return '${MqttConstants.topicPrefix}/$organizationId/$projectId/$deviceId/$channel';
  }

  void _setupMessageListener() {
    _client!.updates?.listen((messages) {
      for (final msg in messages) {
        final pubMsg = msg.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(
          pubMsg.payload.message,
        );
        _messageController.add(
          NexlozaMqttMessage(
            topic: msg.topic,
            payload: text,
            receivedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void _onConnected() {
    _updateStatus(MqttConnectionStatus.connected);
    AppLogger.info('MQTT connected');
  }

  void _onDisconnected() {
    _updateStatus(MqttConnectionStatus.disconnected);
    AppLogger.info('MQTT disconnected');
  }

  void _onAutoReconnect() {
    _updateStatus(MqttConnectionStatus.connecting);
    AppLogger.info('MQTT auto-reconnecting');
  }

  void _onAutoReconnected() {
    _updateStatus(MqttConnectionStatus.connected);
    AppLogger.info('MQTT auto-reconnected');
  }

  void _updateStatus(MqttConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
}

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(() => service.dispose());
  return service;
});

final mqttStatusProvider = StreamProvider<MqttConnectionStatus>((ref) {
  return ref.watch(mqttServiceProvider).statusStream;
});

final mqttMessagesProvider = StreamProvider<NexlozaMqttMessage>((ref) {
  return ref.watch(mqttServiceProvider).messageStream;
});
