abstract final class MqttConstants {
  static const int defaultPort = 1883;
  static const int defaultTlsPort = 8883;
  static const int defaultWsPort = 8083;
  static const int keepAliveSeconds = 30;
  static const int reconnectDelaySeconds = 5;
  static const int maxReconnectAttempts = 10;

  static const String topicVersion = 'v1';
  static const String topicPrefix = 'nexloza/$topicVersion';

  static const int qosTelemetry = 0;
  static const int qosCommand = 1;
  static const int qosCommandAck = 1;
  static const int qosState = 1;
  static const int qosStatus = 1;

  static String _base(String orgId, String projectId, String deviceId) =>
      '$topicPrefix/$orgId/$projectId/$deviceId';

  static String telemetryTopic(
    String orgId,
    String projectId,
    String deviceId,
  ) => '${_base(orgId, projectId, deviceId)}/telemetry';

  static String commandTopic(String orgId, String projectId, String deviceId) =>
      '${_base(orgId, projectId, deviceId)}/command';

  static String commandAckTopic(
    String orgId,
    String projectId,
    String deviceId,
  ) => '${_base(orgId, projectId, deviceId)}/command-ack';

  static String stateTopic(String orgId, String projectId, String deviceId) =>
      '${_base(orgId, projectId, deviceId)}/state';

  static String statusTopic(String orgId, String projectId, String deviceId) =>
      '${_base(orgId, projectId, deviceId)}/status';

  static String configTopic(String orgId, String projectId, String deviceId) =>
      '${_base(orgId, projectId, deviceId)}/config';

  static String deviceWildcard(
    String orgId,
    String projectId,
    String deviceId,
  ) => '${_base(orgId, projectId, deviceId)}/#';

  static String projectWildcard(String orgId, String projectId) =>
      '$topicPrefix/$orgId/$projectId/#';
}
