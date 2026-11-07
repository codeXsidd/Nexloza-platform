abstract final class AppConstants {
  static const String appName = 'Nexloza';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'One Platform. Unlimited IoT Possibilities.';

  static const int maxProjectsPerUser = 50;
  static const int maxDevicesPerProject = 100;
  static const int maxAutomationsPerProject = 50;
  static const int maxDashboardsPerProject = 10;
  static const int maxWidgetsPerDashboard = 30;

  static const int telemetryRetentionDays = 90;
  static const int defaultSamplingIntervalSeconds = 60;
  static const int heartbeatIntervalSeconds = 30;
  static const int deviceOfflineThresholdSeconds = 120;

  static const int maxAiConversationMessages = 100;
  static const int maxAiRequestsPerHour = 60;

  static const int paginationDefaultLimit = 20;
  static const int searchDebounceMilliseconds = 300;

  static const double qrCodeSize = 200.0;
}
