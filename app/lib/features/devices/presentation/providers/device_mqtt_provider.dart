import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/mqtt_constants.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../../../config/env_config.dart';

class DeviceMqttController {
  final MqttService _mqtt;
  DeviceMqttController(this._mqtt);

  bool get isConnected => _mqtt.status == MqttConnectionStatus.connected;

  Future<bool> connectForDevice({
    required String organizationId,
    required String projectId,
    required String deviceId,
    required String username,
    required String password,
  }) async {
    final connected = await _mqtt.connect(
      host: EnvConfig.mqttHost,
      port: EnvConfig.mqttPort,
      clientId: 'nexloza_app_$deviceId',
      username: username,
      password: password,
      useTls: EnvConfig.mqttTls,
    );

    if (connected) {
      _subscribeToDevice(organizationId, projectId, deviceId);
    }
    return connected;
  }

  void _subscribeToDevice(String orgId, String projectId, String deviceId) {
    _mqtt.subscribe(MqttConstants.telemetryTopic(orgId, projectId, deviceId));
    _mqtt.subscribe(MqttConstants.statusTopic(orgId, projectId, deviceId));
    _mqtt.subscribe(MqttConstants.commandAckTopic(orgId, projectId, deviceId));
    _mqtt.subscribe(MqttConstants.stateTopic(orgId, projectId, deviceId));
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
    _mqtt.disconnect();
  }
}

final deviceMqttControllerProvider = Provider<DeviceMqttController>((ref) {
  return DeviceMqttController(ref.watch(mqttServiceProvider));
});
