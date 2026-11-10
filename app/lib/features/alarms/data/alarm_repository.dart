import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/result.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/alarm_entity.dart';
import '../domain/entities/alarm_activity_entity.dart';

class AlarmRepository {
  final Ref _ref;

  AlarmRepository(this._ref);

  Future<Result<List<Alarm>>> getActiveAlarms(String projectId) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarms')
          .select()
          .eq('project_id', projectId)
          .inFilter('status', ['active', 'acknowledged'])
          .order('severity')
          .order('last_occurred_at', ascending: false);
      final alarms = (response as List).map((j) => Alarm.fromJson(j)).toList();
      return Result.success(alarms);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load active alarms: $e'));
    }
  }

  Future<Result<List<Alarm>>> getAlarmHistory(
    String projectId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarms')
          .select()
          .eq('project_id', projectId)
          .order('last_occurred_at', ascending: false)
          .range(offset, offset + limit - 1);
      final alarms = (response as List).map((j) => Alarm.fromJson(j)).toList();
      return Result.success(alarms);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load alarm history: $e'));
    }
  }

  Future<Result<Alarm>> getAlarmById(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarms')
          .select()
          .eq('id', id)
          .single();
      return Result.success(Alarm.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load alarm: $e'));
    }
  }

  Future<Result<Alarm>> acknowledgeAlarm(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(supabaseAuthProvider).currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Not authenticated'));
      }

      final now = DateTime.now().toIso8601String();
      final response = await supabase
          .from('alarms')
          .update({
            'status': 'acknowledged',
            'acknowledged_by': userId,
            'acknowledged_at': now,
          })
          .eq('id', id)
          .eq('status', 'active')
          .select()
          .single();

      await supabase.from('alarm_activity').insert({
        'alarm_id': id,
        'activity_type': 'acknowledged',
        'performed_by': userId,
      });

      return Result.success(Alarm.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to acknowledge alarm: $e'));
    }
  }

  Future<Result<Alarm>> clearAlarm(String id, {String? reason}) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(supabaseAuthProvider).currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Not authenticated'));
      }

      final now = DateTime.now().toIso8601String();
      final response = await supabase
          .from('alarms')
          .update({
            'status': 'cleared',
            'cleared_by': userId,
            'cleared_at': now,
            'cleared_reason': reason ?? 'Manually cleared',
          })
          .eq('id', id)
          .select()
          .single();

      await supabase.from('alarm_activity').insert({
        'alarm_id': id,
        'activity_type': 'cleared',
        'performed_by': userId,
        'comment': reason ?? 'Manually cleared',
      });

      // Cancel any pending escalation tasks
      await supabase
          .from('escalation_tasks')
          .update({'status': 'cancelled'})
          .eq('alarm_id', id)
          .eq('status', 'pending');

      return Result.success(Alarm.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to clear alarm: $e'));
    }
  }

  Future<Result<void>> addComment(String alarmId, String comment) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(supabaseAuthProvider).currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Not authenticated'));
      }

      await supabase.from('alarm_activity').insert({
        'alarm_id': alarmId,
        'activity_type': 'comment_added',
        'performed_by': userId,
        'comment': comment,
      });

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to add comment: $e'));
    }
  }

  Future<Result<List<AlarmActivity>>> getAlarmActivity(String alarmId) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarm_activity')
          .select()
          .eq('alarm_id', alarmId)
          .order('created_at', ascending: false);
      final activities = (response as List)
          .map((j) => AlarmActivity.fromJson(j))
          .toList();
      return Result.success(activities);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load alarm activity: $e'));
    }
  }

  Future<Result<AlarmStats>> getAlarmStats(String projectId) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarms')
          .select()
          .eq('project_id', projectId)
          .inFilter('status', ['active', 'acknowledged']);
      final alarms = (response as List).map((j) => Alarm.fromJson(j)).toList();
      return Result.success(AlarmStats.fromAlarms(alarms));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load alarm stats: $e'));
    }
  }

  Future<Result<void>> bulkAcknowledge(
    String projectId,
    List<String> alarmIds,
  ) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(supabaseAuthProvider).currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Not authenticated'));
      }

      final now = DateTime.now().toIso8601String();
      await supabase
          .from('alarms')
          .update({
            'status': 'acknowledged',
            'acknowledged_by': userId,
            'acknowledged_at': now,
          })
          .inFilter('id', alarmIds)
          .eq('status', 'active');

      for (final id in alarmIds) {
        await supabase.from('alarm_activity').insert({
          'alarm_id': id,
          'activity_type': 'acknowledged',
          'performed_by': userId,
          'comment': 'Bulk acknowledged',
        });
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to bulk acknowledge alarms: $e'),
      );
    }
  }
}

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(ref);
});
