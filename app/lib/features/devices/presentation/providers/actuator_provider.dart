import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../data/actuator_repository.dart';
import '../../domain/entities/actuator_entity.dart';

final deviceActuatorsProvider =
    FutureProvider.family<List<ActuatorDefinition>, String>((
      ref,
      deviceId,
    ) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(actuatorRepositoryProvider);
      final result = await repo.getActuators(deviceId: deviceId);
      return result.when(success: (data) => data, failure: (_) => []);
    });
