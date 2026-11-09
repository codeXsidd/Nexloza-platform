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

  Future<bool> connectForDevice(String deviceId) async {
    if (isConnected) {
      _subscribeToDevice(deviceId);
      return true;
    }

    final connected = await _mqtt.connect(
      host: EnvConfig.mqttHost,
      port: EnvConfig.mqttPort,
      clientId: 'nexloza_app_$deviceId',
    );

    if (connected) {
      _subscribeToDevice(deviceId);
      _listenForAcknowledgements(deviceId);
    }
    return connected;
  }

  void _subscribeToDevice(String deviceId) {
    _mqtt.subscribe(MqttConstants.telemetryTopic(deviceId));
    _mqtt.subscribe(MqttConstants.statusTopic(deviceId));
    _mqtt.subscribe(MqttConstants.commandResponseTopic(deviceId));
  }

  void _listenForAcknowledgements(String deviceId) {
    _mqtt.messageStream.listen((msg) {
      if (msg.topic == MqttConstants.commandResponseTopic(deviceId)) {
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

  void disconnectFromDevice(String deviceId) {
    _mqtt.unsubscribe(MqttConstants.telemetryTopic(deviceId));
    _mqtt.unsubscribe(MqttConstants.statusTopic(deviceId));
    _mqtt.unsubscribe(MqttConstants.commandResponseTopic(deviceId));
  }
}

final deviceMqttControllerProvider = Provider<DeviceMqttController>((ref) {
  return DeviceMqttController(
    ref.watch(mqttServiceProvider),
    ref.watch(commandRepositoryProvider),
  );
});
