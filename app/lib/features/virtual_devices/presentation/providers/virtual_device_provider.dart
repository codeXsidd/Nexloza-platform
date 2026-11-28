import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../../devices/domain/entities/device_entity.dart';
import '../../data/virtual_device_repository.dart';
import '../../data/digital_twin_repository.dart';
import '../../data/simulator_engine.dart';
import '../../data/telemetry_publisher.dart';
import '../../domain/entities/simulation_profile.dart';
import '../../domain/entities/simulator_state.dart';
import '../../domain/entities/digital_twin_state.dart';

final virtualDevicesProvider = FutureProvider.family<List<Device>, String>((
  ref,
  projectId,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.watch(virtualDeviceRepositoryProvider);
  final result = await repo.getVirtualDevices(projectId: projectId);
  return result.when(success: (devices) => devices, failure: (_) => []);
});

final simulatorStateProvider =
    StreamProvider.family<SimulatorDeviceState?, String>((ref, deviceId) {
      final engine = ref.watch(simulatorEngineProvider);
      final controller = StreamController<SimulatorDeviceState?>();

      final initial = engine.getState(deviceId);
      controller.add(initial);

      final sub = engine.stateStream
          .where((s) => s.deviceId == deviceId)
          .listen((s) => controller.add(s));

      ref.onDispose(() {
        sub.cancel();
        controller.close();
      });

      return controller.stream;
    });

final digitalTwinProvider = FutureProvider.family<DigitalTwinState?, String>((
  ref,
  deviceId,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.watch(digitalTwinRepositoryProvider);
  final result = await repo.getState(deviceId);
  return result.when(success: (state) => state, failure: (_) => null);
});

class VirtualDeviceController {
  final VirtualDeviceRepository _repo;
  final SimulatorEngine _engine;
  final TelemetryPublisher _publisher;
  final DigitalTwinRepository _twinRepo;

  VirtualDeviceController(
    this._repo,
    this._engine,
    this._publisher,
    this._twinRepo,
  );

  Future<Device?> createVirtualDevice({
    required String projectId,
    required String name,
    String? description,
    required SimulationProfileType profileType,
  }) async {
    final result = await _repo.createVirtualDevice(
      projectId: projectId,
      name: name,
      description: description,
      profileType: profileType,
    );
    return result.when(success: (device) => device, failure: (_) => null);
  }

  Future<bool> startSimulation({
    required String deviceId,
    required String projectId,
    required String organizationId,
    required SimulationProfileType profileType,
    int? seed,
    ({String username, String password})? credentials,
  }) async {
    final profile = SimulationProfiles.forType(profileType);
    final ready = await _publisher.startPublishing(
      deviceId: deviceId,
      projectId: projectId,
      organizationId: organizationId,
      credentials: credentials,
    );
    if (ready) {
      _engine.startSimulation(deviceId: deviceId, profile: profile, seed: seed);
    }
    return ready;
  }

  void pauseSimulation(String deviceId) {
    _engine.pauseSimulation(deviceId);
  }

  void resumeSimulation(String deviceId) {
    _engine.resumeSimulation(deviceId);
  }

  void stopSimulation(String deviceId) {
    _engine.stopSimulation(deviceId);
    _publisher.stopPublishing(deviceId);
  }

  void resetSimulation(String deviceId) {
    _engine.resetSimulation(deviceId);
  }

  void setSpeed(String deviceId, double speed) {
    _engine.setSpeed(deviceId, speed);
  }

  void enableFault(String deviceId, String sensorKey, FaultScenario fault) {
    _engine.enableFault(deviceId, sensorKey, fault);
  }

  void disableFault(String deviceId, String sensorKey) {
    _engine.disableFault(deviceId, sensorKey);
  }

  Future<void> updateDesiredState({
    required String deviceId,
    required Map<String, dynamic> attributes,
    required int expectedVersion,
  }) async {
    await _twinRepo.updateDesired(
      deviceId: deviceId,
      attributes: attributes,
      expectedVersion: expectedVersion,
    );
  }

  Future<void> deleteVirtualDevice(String deviceId) async {
    stopSimulation(deviceId);
    await _repo.deleteVirtualDevice(deviceId);
  }
}

final virtualDeviceControllerProvider = Provider<VirtualDeviceController>((
  ref,
) {
  return VirtualDeviceController(
    ref.watch(virtualDeviceRepositoryProvider),
    ref.watch(simulatorEngineProvider),
    ref.watch(telemetryPublisherProvider),
    ref.watch(digitalTwinRepositoryProvider),
  );
});
