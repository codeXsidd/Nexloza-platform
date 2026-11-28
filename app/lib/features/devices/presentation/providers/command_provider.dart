import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../data/command_repository.dart';
import '../../domain/entities/device_command_entity.dart';

final deviceCommandsProvider =
    FutureProvider.family<List<DeviceCommand>, String>((ref, deviceId) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(commandRepositoryProvider);
      final result = await repo.getCommands(deviceId: deviceId);
      return result.when(success: (data) => data, failure: (_) => []);
    });

final commandStreamProvider =
    StreamProvider.family<List<DeviceCommand>, String>((ref, deviceId) {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(commandRepositoryProvider);
      return repo.watchCommands(deviceId);
    });
