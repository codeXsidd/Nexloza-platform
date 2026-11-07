abstract final class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String apiVersion = 'v1';
  static const Duration httpTimeout = Duration(seconds: 30);
  static const Duration mqttKeepAlive = Duration(seconds: 30);
  static const Duration telemetryCacheExpiry = Duration(minutes: 5);
}
