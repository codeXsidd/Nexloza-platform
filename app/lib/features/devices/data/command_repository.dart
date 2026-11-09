import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/mqtt_service.dart';
import '../../../core/constants/mqtt_constants.dart';
import '../domain/entities/device_command_entity.dart';

class CommandRepository {
  final SupabaseClient _client;
  final MqttService _mqtt;

  CommandRepository(this._client, this._mqtt);

  Future<Result<DeviceCommand>> sendCommand({
    required String deviceId,
    required String commandType,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final response = await _client.functions.invoke(
        'device-command',
        body: {
          'device_id': deviceId,
          'command_type': commandType,
          'payload': payload,
        },
      );

      if (response.status != 201) {
        final error = jsonDecode(response.data as String);
        return Result.failure(
          ServerFailure(error['error'] as String? ?? 'Failed to send command'),
        );
      }

      final data = jsonDecode(response.data as String);
      final command = DeviceCommand.fromJson(
        data['command'] as Map<String, dynamic>,
      );

      _publishCommandToMqtt(deviceId, command);

      return Result.success(command);
    } on FunctionException catch (e) {
      return Result.failure(
        ServerFailure(e.details?.toString() ?? e.toString()),
      );
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  void _publishCommandToMqtt(String deviceId, DeviceCommand command) {
    if (_mqtt.status != MqttConnectionStatus.connected) return;

    final topic = MqttConstants.commandTopic(deviceId);
    final payload = jsonEncode({
      'command_id': command.id,
      'command_type': command.commandType,
      'payload': command.payload,
    });
    _mqtt.publish(topic, payload);
  }

  Future<Result<List<DeviceCommand>>> getCommands({
    required String deviceId,
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('device_commands')
          .select()
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .limit(limit);
      final commands = (response as List)
          .map((e) => DeviceCommand.fromJson(e))
          .toList();
      return Result.success(commands);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> updateCommandStatus(
    String commandId,
    CommandStatus status, {
    String? errorMessage,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status.name};
      if (status == CommandStatus.sent) {
        updates['sent_at'] = DateTime.now().toIso8601String();
      } else if (status == CommandStatus.acknowledged) {
        updates['acknowledged_at'] = DateTime.now().toIso8601String();
      } else if (status == CommandStatus.executed) {
        updates['executed_at'] = DateTime.now().toIso8601String();
      }
      if (errorMessage != null) updates['error_message'] = errorMessage;

      await _client.from('device_commands').update(updates).eq('id', commandId);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Stream<List<DeviceCommand>> watchCommands(String deviceId) {
    return _client
        .from('device_commands')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) => data.map((e) => DeviceCommand.fromJson(e)).toList());
  }
}

final commandRepositoryProvider = Provider<CommandRepository>((ref) {
  return CommandRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(mqttServiceProvider),
  );
});
