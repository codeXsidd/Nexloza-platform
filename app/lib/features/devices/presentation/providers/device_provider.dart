import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../data/device_repository.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/entities/device_credential_entity.dart';

class DevicesNotifier extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() async {
    ref.watch(offlineAccountProvider);
    final repo = ref.read(deviceRepositoryProvider);
    final result = await repo.getDevices();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Device?> addDevice({
    required String projectId,
    required String name,
    required String deviceType,
    String hardwarePlatform = 'esp32',
  }) async {
    final repo = ref.read(deviceRepositoryProvider);
    final result = await repo.addDevice(
      projectId: projectId,
      name: name,
      deviceType: deviceType,
      hardwarePlatform: hardwarePlatform,
    );
    return result.when(
      success: (device) {
        ref.invalidateSelf();
        return device;
      },
      failure: (_) => null,
    );
  }

  Future<bool> updateDevice(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(deviceRepositoryProvider);
    final result = await repo.updateDevice(id, updates);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteDevice(String id) async {
    final repo = ref.read(deviceRepositoryProvider);
    final result = await repo.deleteDevice(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<ProvisionedCredential?> provisionCredentials(String deviceId) async {
    final repo = ref.read(deviceRepositoryProvider);
    final result = await repo.provisionCredentials(deviceId);
    return result.when(success: (cred) => cred, failure: (_) => null);
  }
}

final devicesProvider = AsyncNotifierProvider<DevicesNotifier, List<Device>>(
  DevicesNotifier.new,
);

final projectDevicesProvider = FutureProvider.family<List<Device>, String>((
  ref,
  projectId,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.read(deviceRepositoryProvider);
  final result = await repo.getDevices(projectId: projectId);
  return result.when(success: (data) => data, failure: (_) => []);
});

final deviceDetailProvider = FutureProvider.family<Device?, String>((
  ref,
  id,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.read(deviceRepositoryProvider);
  final result = await repo.getDevice(id);
  return result.when(success: (d) => d, failure: (_) => null);
});

final deviceCredentialsProvider =
    FutureProvider.family<List<DeviceCredential>, String>((
      ref,
      deviceId,
    ) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(deviceRepositoryProvider);
      final result = await repo.getCredentials(deviceId);
      return result.when(success: (data) => data, failure: (_) => []);
    });
