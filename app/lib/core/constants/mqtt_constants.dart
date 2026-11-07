abstract final class MqttConstants {
  static const int defaultPort = 1883;
  static const int defaultTlsPort = 8883;
  static const int defaultWsPort = 8083;
  static const int keepAliveSeconds = 30;
  static const int reconnectDelaySeconds = 5;
  static const int maxReconnectAttempts = 10;

  static const String topicPrefix = 'nexloza';

  static const int qosAtMostOnce = 0;
  static const int qosAtLeastOnce = 1;
  static const int qosExactlyOnce = 2;

  static String telemetryTopic(String deviceId) =>
      'nexloza/devices/$deviceId/telemetry';

  static String commandTopic(String deviceId) =>
      'nexloza/devices/$deviceId/commands';

  static String commandResponseTopic(String deviceId) =>
      'nexloza/devices/$deviceId/commands/response';

  static String statusTopic(String deviceId) =>
      'nexloza/devices/$deviceId/status';

  static String heartbeatTopic(String deviceId) =>
      'nexloza/devices/$deviceId/heartbeat';

  static String otaTopic(String deviceId) => 'nexloza/devices/$deviceId/ota';
}
