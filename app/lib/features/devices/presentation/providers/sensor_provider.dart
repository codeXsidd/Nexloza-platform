import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sensor_repository.dart';
import '../../domain/entities/sensor_entity.dart';

final deviceSensorsProvider =
    FutureProvider.family<List<SensorDefinition>, String>((
      ref,
      deviceId,
    ) async {
      final repo = ref.read(sensorRepositoryProvider);
      final result = await repo.getSensors(deviceId: deviceId);
      return result.when(success: (data) => data, failure: (_) => []);
    });

final projectSensorsProvider =
    FutureProvider.family<List<SensorDefinition>, String>((
      ref,
      projectId,
    ) async {
      final repo = ref.read(sensorRepositoryProvider);
      final result = await repo.getProjectSensors(projectId: projectId);
      return result.when(success: (data) => data, failure: (_) => []);
    });
