import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/actuator_entity.dart';

class ActuatorRepository {
  final SupabaseClient _client;

  final OfflineSyncService? _offline;

  ActuatorRepository(this._client, [this._offline]);

  Future<Result<List<ActuatorDefinition>>> getActuators({
    required String deviceId,
  }) async {
    try {
      final response = await cachedRead(
        _offline,
        'capabilities',
        deviceId,
        'actuators',
        () async => await _client
            .from('actuator_definitions')
            .select()
            .eq('device_id', deviceId)
            .order('created_at'),
      );
      final actuators = (response as List)
          .map((e) => ActuatorDefinition.fromJson(e))
          .toList();
      return Result.success(actuators);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<ActuatorDefinition>> createActuator({
    required String deviceId,
    required String projectId,
    required String name,
    required String actuatorType,
    required String controlType,
    required String commandKey,
    String? telemetryKey,
    double minValue = 0,
    double maxValue = 1,
    double step = 1,
  }) async {
    try {
      final response = await _client
          .from('actuator_definitions')
          .insert({
            'device_id': deviceId,
            'project_id': projectId,
            'name': name,
            'actuator_type': actuatorType,
            'control_type': controlType,
            'command_key': commandKey,
            'telemetry_key': telemetryKey,
            'min_value': minValue,
            'max_value': maxValue,
            'step': step,
          })
          .select()
          .single();
      return Result.success(ActuatorDefinition.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<ActuatorDefinition>> updateActuator(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('actuator_definitions')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Result.success(ActuatorDefinition.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteActuator(String id) async {
    try {
      await _client.from('actuator_definitions').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final actuatorRepositoryProvider = Provider<ActuatorRepository>((ref) {
  return ActuatorRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(offlineSyncProvider),
  );
});
