import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../../devices/domain/entities/device_entity.dart';
import '../domain/entities/simulation_profile.dart';

class VirtualDeviceRepository {
  final SupabaseClient _client;

  VirtualDeviceRepository(this._client);

  Future<Result<Device>> createVirtualDevice({
    required String projectId,
    required String name,
    String? description,
    required SimulationProfileType profileType,
  }) async {
    try {
      final profile = SimulationProfiles.forType(profileType);

      final deviceResponse = await _client
          .from('devices')
          .insert({
            'project_id': projectId,
            'name': name,
            'description': description,
            'device_type': 'virtual_${profileType.dbValue}',
            'hardware_platform': 'generic_mqtt',
            'is_virtual': true,
            'simulation_profile': profileType.dbValue,
            'metadata': {
              'simulation_profile': profileType.dbValue,
              'profile_display_name': profileType.displayName,
            },
          })
          .select()
          .single();

      final device = Device.fromJson(deviceResponse);

      if (profile.sensors.isNotEmpty) {
        await _client
            .from('sensor_definitions')
            .insert(
              profile.sensors.map((s) {
                return {
                  'device_id': device.id,
                  'project_id': projectId,
                  'name': s.name,
                  'sensor_type': _mapSensorType(s.sensorType),
                  'telemetry_key': s.telemetryKey,
                  'unit': s.unit.isEmpty ? null : s.unit,
                  'min_value': s.minValue,
                  'max_value': s.maxValue,
                  'sampling_interval_ms': s.updateIntervalMs,
                };
              }).toList(),
            );
      }

      if (profile.actuators.isNotEmpty) {
        await _client
            .from('actuator_definitions')
            .insert(
              profile.actuators.map((a) {
                return {
                  'device_id': device.id,
                  'project_id': projectId,
                  'name': a.name,
                  'actuator_type': _mapActuatorType(a.actuatorType),
                  'control_type': a.controlType,
                  'command_key': a.commandKey,
                  'min_value': a.minValue,
                  'max_value': a.maxValue,
                  'step': a.step,
                  'current_state': {
                    'value': a.initialValue,
                    'is_on': a.initialValue > 0,
                  },
                };
              }).toList(),
            );
      }

      await _client.from('device_twin_state').insert({'device_id': device.id});

      return Result.success(device);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<Device>>> getVirtualDevices({
    required String projectId,
  }) async {
    try {
      final response = await _client
          .from('devices')
          .select()
          .eq('project_id', projectId)
          .eq('is_virtual', true)
          .order('created_at', ascending: false);
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

  Future<Result<void>> deleteVirtualDevice(String deviceId) async {
    try {
      await _client
          .from('devices')
          .delete()
          .eq('id', deviceId)
          .eq('is_virtual', true);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Stream<List<Device>> watchVirtualDevices(String projectId) {
    return _client
        .from('devices')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .map(
          (data) => data
              .where((d) => d['is_virtual'] == true)
              .map((e) => Device.fromJson(e))
              .toList(),
        );
  }

  static const _validSensorTypes = {
    'temperature',
    'humidity',
    'pressure',
    'gas',
    'smoke',
    'motion',
    'ultrasonic',
    'water_level',
    'soil_moisture',
    'light',
    'sound',
    'vibration',
    'current',
    'voltage',
    'energy',
    'gps',
    'air_quality',
    'ph',
    'flow_rate',
    'weight',
    'color',
    'uv',
    'magnetic',
    'custom',
  };

  static const _validActuatorTypes = {
    'relay',
    'light',
    'fan',
    'pump',
    'motor',
    'servo',
    'buzzer',
    'switch',
    'smart_plug',
    'valve',
    'heater',
    'cooler',
    'lock',
    'rgb_led',
    'display',
    'custom',
  };

  static String _mapSensorType(String type) {
    return _validSensorTypes.contains(type) ? type : 'custom';
  }

  static String _mapActuatorType(String type) {
    return _validActuatorTypes.contains(type) ? type : 'custom';
  }
}

final virtualDeviceRepositoryProvider = Provider<VirtualDeviceRepository>((
  ref,
) {
  return VirtualDeviceRepository(ref.watch(supabaseClientProvider));
});
