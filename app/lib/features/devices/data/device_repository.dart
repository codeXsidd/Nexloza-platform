import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/device_entity.dart';
import '../domain/entities/device_credential_entity.dart';

class DeviceRepository {
  final SupabaseClient _client;

  final OfflineSyncService? _offline;

  DeviceRepository(this._client, {OfflineSyncService? offline})
    : _offline = offline;

  Future<Result<List<Device>>> getDevices({
    String? projectId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final response = await cachedRead(
        _offline,
        'devices',
        projectId ?? 'all',
        'page:$page:$pageSize',
        () async {
          var query = _client.from('devices').select();
          if (projectId != null) {
            query = query.eq('project_id', projectId);
          }
          final from = page * pageSize;
          final to = from + pageSize - 1;
          return await query
              .order('created_at', ascending: false)
              .range(from, to);
        },
      );
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
      final response = await cachedRead(
        _offline,
        'devices',
        id,
        'detail',
        () async =>
            await _client.from('devices').select().eq('id', id).single(),
      );
      return Result.success(Device.fromJson(response as Map<String, dynamic>));
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

  Future<Result<Device>> updateDevice(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('devices')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Result.success(Device.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<ProvisionedCredential>> provisionCredentials(
    String deviceId,
  ) async {
    try {
      final apiKey = _generateApiKey();
      final apiSecret = _generateApiSecret();
      final secretHash = _hashSecret(apiSecret);

      final response = await _client
          .from('device_credentials')
          .insert({
            'device_id': deviceId,
            'api_key': apiKey,
            'secret_hash': secretHash,
          })
          .select()
          .single();

      return Result.success(
        ProvisionedCredential(
          apiKey: apiKey,
          apiSecret: apiSecret,
          credential: DeviceCredential.fromJson(response),
        ),
      );
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<DeviceCredential>>> getCredentials(String deviceId) async {
    try {
      final response = await _client
          .from('device_credentials')
          .select()
          .eq('device_id', deviceId)
          .order('created_at', ascending: false);
      final creds = (response as List)
          .map((e) => DeviceCredential.fromJson(e))
          .toList();
      return Result.success(creds);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> revokeCredential(String credentialId) async {
    try {
      await _client
          .from('device_credentials')
          .update({'is_active': false})
          .eq('id', credentialId);
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

  String _generateApiKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(24, (_) => rng.nextInt(256));
    return 'nxl_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  String _generateApiSecret() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashSecret(String secret) {
    final bytes = utf8.encode(secret);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    ref.watch(supabaseClientProvider),
    offline: ref.watch(offlineSyncProvider),
  );
});
