class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Unable to connect. Check your internet connection.',
  ]);
}

class AuthException extends AppException {
  const AuthException([
    super.message = 'Authentication failed. Please sign in again.',
  ]);
}

class DeviceException extends AppException {
  const DeviceException([
    super.message = 'Device communication error.',
  ]);
}

class StorageException extends AppException {
  const StorageException([
    super.message = 'Local storage error.',
  ]);
}

class MqttException extends AppException {
  const MqttException([
    super.message = 'MQTT connection error.',
  ]);
}

class AutomationException extends AppException {
  const AutomationException([
    super.message = 'Automation execution error.',
  ]);
}
