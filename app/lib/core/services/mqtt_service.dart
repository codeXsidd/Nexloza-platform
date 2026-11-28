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
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;
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
    required String username,
    required String password,
    bool useTls = true,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      _updateStatus(MqttConnectionStatus.error);
      return false;
    }
    disconnect();

    _updateStatus(MqttConnectionStatus.connecting);

    final client = MqttServerClient(host, clientId)
      ..port = port
      ..keepAlivePeriod = MqttConstants.keepAliveSeconds
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected;

    client.secure = useTls;
    _client = client;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    connMsg.authenticateAs(username, password);
    client.connectionMessage = connMsg;

    try {
      await client.connect(username, password);
      if (!identical(_client, client)) return false;
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _setupMessageListener();
        return true;
      }
    } catch (_) {
      AppLogger.warning('MQTT connection failed');
    }
    if (identical(_client, client)) {
      disconnect();
      _updateStatus(MqttConnectionStatus.error);
    }
    return false;
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

  bool publish(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      AppLogger.warning('Cannot publish: not connected');
      return false;
    }
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(topic, qos, builder.payload!, retain: retain);
    return true;
  }

  void disconnect() {
    unawaited(_updates?.cancel());
    _updates = null;
    final client = _client;
    _client = null;
    client?.onConnected = null;
    client?.onDisconnected = null;
    client?.onAutoReconnect = null;
    client?.onAutoReconnected = null;
    client?.disconnect();
    _updateStatus(MqttConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }

  void _setupMessageListener() {
    unawaited(_updates?.cancel());
    _updates = _client?.updates?.listen((messages) {
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
    _setupMessageListener();
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
