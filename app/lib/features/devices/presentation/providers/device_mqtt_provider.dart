import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/mqtt_constants.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../../../config/env_config.dart';
import '../../data/command_repository.dart';
import '../../domain/entities/device_command_entity.dart';

class DeviceMqttController {
  final MqttService _mqtt;
  final CommandRepository _commands;

  DeviceMqttController(this._mqtt, this._commands);

  bool get isConnected => _mqtt.status == MqttConnectionStatus.connected;

  Future<bool> connectForDevice({
    required String organizationId,
    required String projectId,
    required String deviceId,
  }) async {
    if (isConnected) {
      _subscribeToDevice(organizationId, projectId, deviceId);
      return true;
    }

    final connected = await _mqtt.connect(
      host: EnvConfig.mqttHost,
      port: EnvConfig.mqttPort,
      clientId: 'nexloza_app_$deviceId',
    );

    if (connected) {
      _subscribeToDevice(organizationId, projectId, deviceId);
      _listenForAcknowledgements(organizationId, projectId, deviceId);
    }
    return connected;
  }

  void _subscribeToDevice(String orgId, String projectId, String deviceId) {
    _mqtt.subscribe(MqttConstants.telemetryTopic(orgId, projectId, deviceId));
    _mqtt.subscribe(MqttConstants.statusTopic(orgId, projectId, deviceId));
    _mqtt.subscribe(MqttConstants.commandAckTopic(orgId, projectId, deviceId));
    _mqtt.subscribe(MqttConstants.stateTopic(orgId, projectId, deviceId));
  }

  void _listenForAcknowledgements(
    String orgId,
    String projectId,
    String deviceId,
  ) {
    final ackTopic = MqttConstants.commandAckTopic(orgId, projectId, deviceId);
    _mqtt.messageStream.listen((msg) {
      if (msg.topic == ackTopic) {
        try {
          final data = jsonDecode(msg.payload) as Map<String, dynamic>;
          final commandId = data['command_id'] as String?;
          final success = data['success'] as bool? ?? false;
          if (commandId != null) {
            _commands.updateCommandStatus(
              commandId,
              success ? CommandStatus.executed : CommandStatus.failed,
              errorMessage: success ? null : data['message'] as String?,
            );
          }
        } catch (_) {}
      }
    });
  }

  void disconnectFromDevice({
    required String organizationId,
    required String projectId,
    required String deviceId,
  }) {
    _mqtt.unsubscribe(
      MqttConstants.telemetryTopic(organizationId, projectId, deviceId),
    );
    _mqtt.unsubscribe(
      MqttConstants.statusTopic(organizationId, projectId, deviceId),
    );
    _mqtt.unsubscribe(
      MqttConstants.commandAckTopic(organizationId, projectId, deviceId),
    );
    _mqtt.unsubscribe(
      MqttConstants.stateTopic(organizationId, projectId, deviceId),
    );
  }
}

final deviceMqttControllerProvider = Provider<DeviceMqttController>((ref) {
  return DeviceMqttController(
    ref.watch(mqttServiceProvider),
    ref.watch(commandRepositoryProvider),
  );
});
