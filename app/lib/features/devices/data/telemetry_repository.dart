import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/telemetry_entity.dart';

class TelemetryRepository {
  final SupabaseClient _client;

  final OfflineSyncService? _offline;

  TelemetryRepository(this._client, [this._offline]);

  Future<Result<List<TelemetryReading>>> getLatestReadings({
    required String deviceId,
    int limit = 50,
  }) async {
    try {
      final response = await cachedRead(
        _offline,
        'telemetry',
        deviceId,
        'latest:$limit',
        () async => await _client
            .from('telemetry')
            .select()
            .eq('device_id', deviceId)
            .order('recorded_at', ascending: false)
            .limit(limit),
      );
      final readings = (response as List)
          .map((e) => TelemetryReading.fromJson(e))
          .toList();
      return Result.success(readings);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<TelemetryReading>>> getSensorReadings({
    required String deviceId,
    required String sensorKey,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    try {
      final response = await cachedRead(
        _offline,
        'telemetry',
        deviceId,
        'sensor:$sensorKey:$from:$to:$limit',
        () async {
          var query = _client
              .from('telemetry')
              .select()
              .eq('device_id', deviceId)
              .eq('sensor_key', sensorKey);

          if (from != null) {
            query = query.gte('recorded_at', from.toIso8601String());
          }
          if (to != null) {
            query = query.lte('recorded_at', to.toIso8601String());
          }

          return await query
              .order('recorded_at', ascending: false)
              .limit(limit);
        },
      );
      final readings = (response as List)
          .map((e) => TelemetryReading.fromJson(e))
          .toList();
      return Result.success(readings);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, TelemetryReading>>> getLatestPerSensor({
    required String deviceId,
  }) async {
    try {
      final response = await cachedRead(
        _offline,
        'telemetry',
        deviceId,
        'per-sensor',
        () async => await _client
            .from('telemetry')
            .select()
            .eq('device_id', deviceId)
            .order('recorded_at', ascending: false)
            .limit(200),
      );

      final readings = <String, TelemetryReading>{};
      for (final row in (response as List)) {
        final reading = TelemetryReading.fromJson(row);
        readings.putIfAbsent(reading.sensorKey, () => reading);
      }
      return Result.success(readings);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Stream<List<TelemetryReading>> watchTelemetry(String deviceId) {
    return _client
        .from('telemetry')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(50)
        .map((data) => data.map((e) => TelemetryReading.fromJson(e)).toList());
  }
}

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  return TelemetryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(offlineSyncProvider),
  );
});
