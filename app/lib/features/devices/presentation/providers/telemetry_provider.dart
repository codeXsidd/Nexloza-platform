import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../data/telemetry_repository.dart';
import '../../domain/entities/telemetry_entity.dart';

final latestTelemetryProvider =
    FutureProvider.family<Map<String, TelemetryReading>, String>((
      ref,
      deviceId,
    ) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(telemetryRepositoryProvider);
      final result = await repo.getLatestPerSensor(deviceId: deviceId);
      return result.when(success: (data) => data, failure: (_) => {});
    });

final telemetryHistoryProvider =
    FutureProvider.family<
      List<TelemetryReading>,
      ({String deviceId, String sensorKey})
    >((ref, params) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(telemetryRepositoryProvider);
      final result = await repo.getSensorReadings(
        deviceId: params.deviceId,
        sensorKey: params.sensorKey,
      );
      return result.when(success: (data) => data, failure: (_) => []);
    });

final telemetryStreamProvider =
    StreamProvider.family<List<TelemetryReading>, String>((ref, deviceId) {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(telemetryRepositoryProvider);
      return repo.watchTelemetry(deviceId);
    });
