abstract final class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String mqttHost = String.fromEnvironment(
    'MQTT_HOST',
    defaultValue: 'localhost',
  );

  static const int mqttPort = int.fromEnvironment(
    'MQTT_PORT',
    defaultValue: 1883,
  );

  static const bool mqttTls = bool.fromEnvironment(
    'MQTT_TLS',
    defaultValue: true,
  );

  static const String bedrockRegion = String.fromEnvironment(
    'BEDROCK_REGION',
    defaultValue: 'us-east-1',
  );
}
