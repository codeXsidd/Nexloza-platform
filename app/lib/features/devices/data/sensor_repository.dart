import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/sensor_entity.dart';

class SensorRepository {
  final SupabaseClient _client;

  SensorRepository(this._client);

  Future<Result<List<SensorDefinition>>> getSensors({
    required String deviceId,
  }) async {
    try {
      final response = await _client
          .from('sensor_definitions')
          .select()
          .eq('device_id', deviceId)
          .order('created_at');
      final sensors = (response as List)
          .map((e) => SensorDefinition.fromJson(e))
          .toList();
      return Result.success(sensors);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<SensorDefinition>>> getProjectSensors({
    required String projectId,
  }) async {
    try {
      final response = await _client
          .from('sensor_definitions')
          .select()
          .eq('project_id', projectId)
          .order('created_at');
      final sensors = (response as List)
          .map((e) => SensorDefinition.fromJson(e))
          .toList();
      return Result.success(sensors);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<SensorDefinition>> createSensor({
    required String deviceId,
    required String projectId,
    required String name,
    required String sensorType,
    required String telemetryKey,
    String? unit,
    int samplingIntervalMs = 60000,
    double? minValue,
    double? maxValue,
    double? warningThresholdHigh,
    double? criticalThresholdHigh,
  }) async {
    try {
      final response = await _client
          .from('sensor_definitions')
          .insert({
            'device_id': deviceId,
            'project_id': projectId,
            'name': name,
            'sensor_type': sensorType,
            'telemetry_key': telemetryKey,
            'unit': unit,
            'sampling_interval_ms': samplingIntervalMs,
            'min_value': minValue,
            'max_value': maxValue,
            'warning_threshold_high': warningThresholdHigh,
            'critical_threshold_high': criticalThresholdHigh,
          })
          .select()
          .single();
      return Result.success(SensorDefinition.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<SensorDefinition>> updateSensor(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('sensor_definitions')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Result.success(SensorDefinition.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteSensor(String id) async {
    try {
      await _client.from('sensor_definitions').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return SensorRepository(ref.watch(supabaseClientProvider));
});
