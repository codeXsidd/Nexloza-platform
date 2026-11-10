import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/alarm_repository.dart';
import '../../data/alarm_config_repository.dart';
import '../../data/escalation_repository.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_activity_entity.dart';
import '../../domain/entities/alarm_configuration_entity.dart';
import '../../domain/entities/escalation_policy_entity.dart';

final activeAlarmsProvider = FutureProvider.autoDispose
    .family<List<Alarm>, String>((ref, projectId) async {
      final repo = ref.read(alarmRepositoryProvider);
      final result = await repo.getActiveAlarms(projectId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

final alarmHistoryProvider = FutureProvider.autoDispose
    .family<List<Alarm>, String>((ref, projectId) async {
      final repo = ref.read(alarmRepositoryProvider);
      final result = await repo.getAlarmHistory(projectId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

final alarmDetailProvider = FutureProvider.autoDispose.family<Alarm, String>((
  ref,
  alarmId,
) async {
  final repo = ref.read(alarmRepositoryProvider);
  final result = await repo.getAlarmById(alarmId);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final alarmActivityProvider = FutureProvider.autoDispose
    .family<List<AlarmActivity>, String>((ref, alarmId) async {
      final repo = ref.read(alarmRepositoryProvider);
      final result = await repo.getAlarmActivity(alarmId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

final alarmStatsProvider = FutureProvider.autoDispose
    .family<AlarmStats, String>((ref, projectId) async {
      final repo = ref.read(alarmRepositoryProvider);
      final result = await repo.getAlarmStats(projectId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

final alarmConfigsProvider = FutureProvider.autoDispose
    .family<List<AlarmConfiguration>, String>((ref, projectId) async {
      final repo = ref.read(alarmConfigRepositoryProvider);
      final result = await repo.getConfigurations(projectId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

final escalationPoliciesProvider = FutureProvider.autoDispose
    .family<List<EscalationPolicy>, String>((ref, projectId) async {
      final repo = ref.read(escalationRepositoryProvider);
      final result = await repo.getPolicies(projectId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

final escalationPolicyDetailProvider = FutureProvider.autoDispose
    .family<EscalationPolicy, String>((ref, policyId) async {
      final repo = ref.read(escalationRepositoryProvider);
      final result = await repo.getPolicyById(policyId);
      return result.when(
        success: (data) => data,
        failure: (f) => throw Exception(f.message),
      );
    });

class AlarmActionNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isLoading = false;
  String? _errorMessage;

  AlarmActionNotifier(this._ref);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> acknowledgeAlarm(String alarmId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final repo = _ref.read(alarmRepositoryProvider);
    final result = await repo.acknowledgeAlarm(alarmId);

    _isLoading = false;
    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> clearAlarm(String alarmId, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final repo = _ref.read(alarmRepositoryProvider);
    final result = await repo.clearAlarm(alarmId, reason: reason);

    _isLoading = false;
    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> addComment(String alarmId, String comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final repo = _ref.read(alarmRepositoryProvider);
    final result = await repo.addComment(alarmId, comment);

    _isLoading = false;
    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> bulkAcknowledge(String projectId, List<String> alarmIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final repo = _ref.read(alarmRepositoryProvider);
    final result = await repo.bulkAcknowledge(projectId, alarmIds);

    _isLoading = false;
    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
    );
  }
}

final alarmActionProvider =
    ChangeNotifierProvider.autoDispose<AlarmActionNotifier>(
      (ref) => AlarmActionNotifier(ref),
    );
