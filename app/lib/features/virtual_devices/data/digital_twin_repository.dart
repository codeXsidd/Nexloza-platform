import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/digital_twin_state.dart';

class DigitalTwinRepository {
  final SupabaseClient _client;

  final OfflineSyncService? _offline;

  DigitalTwinRepository(this._client, [this._offline]);

  Future<Result<DigitalTwinState>> getState(String deviceId) async {
    try {
      final response = await cachedRead(
        _offline,
        'state',
        deviceId,
        'detail',
        () async => await _client
            .from('device_twin_state')
            .select()
            .eq('device_id', deviceId)
            .single(),
      );
      return Result.success(
        DigitalTwinState.fromJson(response as Map<String, dynamic>),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<DigitalTwinState>> createState(String deviceId) async {
    try {
      final response = await _client
          .from('device_twin_state')
          .insert({'device_id': deviceId})
          .select()
          .single();
      return Result.success(DigitalTwinState.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<DigitalTwinState>> updateReported({
    required String deviceId,
    required Map<String, dynamic> attributes,
  }) async {
    try {
      final existing = await _client
          .from('device_twin_state')
          .select()
          .eq('device_id', deviceId)
          .single();

      final current = existing['reported_state'] as Map<String, dynamic>? ?? {};
      final merged = {...current, ...attributes};
      final desired = existing['desired_state'] as Map<String, dynamic>? ?? {};
      final version = (existing['reported_version'] as int? ?? 0) + 1;

      bool inSync = true;
      for (final key in desired.keys) {
        if (merged[key] != desired[key]) {
          inSync = false;
          break;
        }
      }

      final now = DateTime.now().toIso8601String();
      final updates = <String, dynamic>{
        'reported_state': merged,
        'reported_version': version,
        'reported_at': now,
        'sync_status': inSync ? 'synced' : 'pending',
      };
      if (inSync) {
        updates['last_sync_at'] = now;
      }

      final response = await _client
          .from('device_twin_state')
          .update(updates)
          .eq('device_id', deviceId)
          .select()
          .single();
      return Result.success(DigitalTwinState.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<DigitalTwinState>> updateDesired({
    required String deviceId,
    required Map<String, dynamic> attributes,
    required int expectedVersion,
  }) async {
    try {
      final existing = await _client
          .from('device_twin_state')
          .select()
          .eq('device_id', deviceId)
          .single();

      final currentVersion = existing['desired_version'] as int? ?? 0;
      if (currentVersion != expectedVersion) {
        return Result.failure(
          const ValidationFailure(
            'Version conflict: desired state was modified concurrently',
          ),
        );
      }

      final current = existing['desired_state'] as Map<String, dynamic>? ?? {};
      final merged = {...current, ...attributes};
      final newVersion = currentVersion + 1;
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('device_twin_state')
          .update({
            'desired_state': merged,
            'desired_version': newVersion,
            'desired_at': now,
            'sync_status': 'pending',
          })
          .eq('device_id', deviceId)
          .select()
          .single();
      return Result.success(DigitalTwinState.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> setSyncStatus(
    String deviceId,
    TwinSyncStatus status,
  ) async {
    try {
      final updates = <String, dynamic>{'sync_status': status.name};
      if (status == TwinSyncStatus.synced) {
        updates['last_sync_at'] = DateTime.now().toIso8601String();
      }
      await _client
          .from('device_twin_state')
          .update(updates)
          .eq('device_id', deviceId);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Stream<DigitalTwinState> watchState(String deviceId) {
    return _client
        .from('device_twin_state')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .map((data) {
          if (data.isEmpty) {
            throw StateError('No twin state found for device $deviceId');
          }
          return DigitalTwinState.fromJson(data.first);
        });
  }
}

final digitalTwinRepositoryProvider = Provider<DigitalTwinRepository>((ref) {
  return DigitalTwinRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(offlineSyncProvider),
  );
});
