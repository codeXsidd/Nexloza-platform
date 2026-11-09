import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../devices/domain/entities/telemetry_entity.dart';

class TelemetryDataService {
  final SupabaseClient _client;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, StreamController<TelemetryReading>> _controllers = {};
  final Map<String, int> _refCounts = {};
  final Map<String, TelemetryReading> _latestValues = {};

  TelemetryDataService(this._client);

  TelemetryReading? getLatest(String deviceId, String sensorKey) {
    return _latestValues['$deviceId:$sensorKey'];
  }

  Stream<TelemetryReading> subscribe(String deviceId, String sensorKey) {
    final key = '$deviceId:$sensorKey';
    _refCounts[key] = (_refCounts[key] ?? 0) + 1;

    if (!_controllers.containsKey(key)) {
      _controllers[key] = StreamController<TelemetryReading>.broadcast();
      _startSubscription(deviceId, sensorKey, key);
    }

    return _controllers[key]!.stream;
  }

  void unsubscribe(String deviceId, String sensorKey) {
    final key = '$deviceId:$sensorKey';
    final count = (_refCounts[key] ?? 1) - 1;
    if (count <= 0) {
      _refCounts.remove(key);
      _subscriptions[key]?.cancel();
      _subscriptions.remove(key);
      _controllers[key]?.close();
      _controllers.remove(key);
      _latestValues.remove(key);
    } else {
      _refCounts[key] = count;
    }
  }

  void _startSubscription(String deviceId, String sensorKey, String key) {
    final stream = _client
        .from('telemetry')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1);

    _subscriptions[key] = stream.listen((data) {
      for (final row in data) {
        final reading = TelemetryReading.fromJson(row);
        if (reading.sensorKey == sensorKey) {
          _latestValues[key] = reading;
          _controllers[key]?.add(reading);
        }
      }
    });
  }

  Future<List<TelemetryReading>> getHistory({
    required String deviceId,
    required String sensorKey,
    required DateTime from,
    required DateTime to,
    int limit = 500,
  }) async {
    final response = await _client
        .from('telemetry')
        .select()
        .eq('device_id', deviceId)
        .eq('sensor_key', sensorKey)
        .gte('recorded_at', from.toIso8601String())
        .lte('recorded_at', to.toIso8601String())
        .order('recorded_at')
        .limit(limit);
    return (response as List).map((e) => TelemetryReading.fromJson(e)).toList();
  }

  Future<Map<String, TelemetryReading>> getLatestForDevice(
    String deviceId,
  ) async {
    final response = await _client
        .from('telemetry')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(200);

    final readings = <String, TelemetryReading>{};
    for (final row in (response as List)) {
      final reading = TelemetryReading.fromJson(row);
      readings.putIfAbsent(reading.sensorKey, () => reading);
    }
    return readings;
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    for (final ctrl in _controllers.values) {
      ctrl.close();
    }
    _subscriptions.clear();
    _controllers.clear();
    _refCounts.clear();
    _latestValues.clear();
  }
}

final telemetryDataServiceProvider = Provider<TelemetryDataService>((ref) {
  final service = TelemetryDataService(ref.watch(supabaseClientProvider));
  ref.onDispose(() => service.dispose());
  return service;
});
