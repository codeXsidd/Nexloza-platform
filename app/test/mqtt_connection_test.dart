import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/core/services/mqtt_service.dart';

void main() {
  test('MQTT requires both credential fields before connecting', () async {
    final service = MqttService();
    addTearDown(service.dispose);

    expect(
      await service.connect(
        host: '127.0.0.1',
        port: 1,
        clientId: 'test',
        username: '',
        password: 'test-secret',
      ),
      isFalse,
    );
    expect(service.status, MqttConnectionStatus.error);
  });

  test('MQTT sends device credentials and reports connected status', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final service = MqttService();
    addTearDown(service.dispose);

    final packet = server.first.then((socket) async {
      addTearDown(socket.destroy);
      final bytes = await socket.first;
      socket.add([0x20, 0x02, 0x00, 0x00]);
      await socket.flush();
      return latin1.decode(bytes);
    });

    expect(
      await service.connect(
        host: '127.0.0.1',
        port: server.port,
        clientId: 'test',
        username: 'device-key',
        password: 'device-secret',
        useTls: false,
      ),
      isTrue,
    );
    final sent = await packet;
    expect(sent, contains('device-key'));
    expect(sent, contains('device-secret'));
    expect(service.status, MqttConnectionStatus.connected);
    service.disconnect();
    expect(service.status, MqttConnectionStatus.disconnected);
  });
}
