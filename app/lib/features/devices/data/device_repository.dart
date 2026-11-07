import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/device_entity.dart';

class DeviceRepository {
  final SupabaseClient _client;

  DeviceRepository(this._client);

  Future<Result<List<Device>>> getDevices({
    String? projectId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client.from('devices').select();
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);
      final devices = (response as List)
          .map((e) => Device.fromJson(e))
          .toList();
      return Result.success(devices);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Device>> getDevice(String id) async {
    try {
      final response = await _client
          .from('devices')
          .select()
          .eq('id', id)
          .single();
      return Result.success(Device.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Device>> addDevice({
    required String projectId,
    required String name,
    required String deviceType,
    String hardwarePlatform = 'esp32',
  }) async {
    try {
      final response = await _client
          .from('devices')
          .insert({
            'project_id': projectId,
            'name': name,
            'device_type': deviceType,
            'hardware_platform': hardwarePlatform,
          })
          .select()
          .single();
      return Result.success(Device.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteDevice(String id) async {
    try {
      await _client.from('devices').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Stream<List<Device>> watchDevices(String projectId) {
    return _client
        .from('devices')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .map((data) => data.map((e) => Device.fromJson(e)).toList());
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(supabaseClientProvider));
});
