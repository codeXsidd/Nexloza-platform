import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/rule_execution.dart';

class RuleExecutionRepository {
  final SupabaseClient _client;

  RuleExecutionRepository(this._client);

  Future<Result<List<RuleExecution>>> getExecutions({
    required String automationId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await _client
          .from('automation_executions')
          .select()
          .eq('automation_id', automationId)
          .order('started_at', ascending: false)
          .range(from, to);
      final executions = (response as List)
          .map((e) => RuleExecution.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(executions);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleExecution>> getExecution(String executionId) async {
    try {
      final response = await _client
          .from('automation_executions')
          .select()
          .eq('id', executionId)
          .single();
      return Result.success(RuleExecution.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<RuleExecution>>> getExecutionsByCorrelation(
    String correlationId,
  ) async {
    try {
      final response = await _client
          .from('automation_executions')
          .select()
          .eq('correlation_id', correlationId)
          .order('started_at');
      final executions = (response as List)
          .map((e) => RuleExecution.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(executions);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<RuleExecution>>> getRecentExecutions({
    required String projectId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('automation_executions')
          .select('*, automations!inner(project_id)')
          .eq('automations.project_id', projectId)
          .order('started_at', ascending: false)
          .limit(limit);
      final executions = (response as List)
          .map((e) => RuleExecution.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(executions);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, int>>> getExecutionStats(
    String automationId,
  ) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1)).toIso8601String();
      final oneWeekAgo = now
          .subtract(const Duration(days: 7))
          .toIso8601String();

      final dayResponse = await _client
          .from('automation_executions')
          .select('status')
          .eq('automation_id', automationId)
          .gte('started_at', oneDayAgo);

      final weekResponse = await _client
          .from('automation_executions')
          .select('status')
          .eq('automation_id', automationId)
          .gte('started_at', oneWeekAgo);

      int dayCompleted = 0, dayFailed = 0;
      for (final row in dayResponse as List) {
        final s = row['status'] as String?;
        if (s == 'completed') dayCompleted++;
        if (s == 'failed') dayFailed++;
      }

      int weekCompleted = 0, weekFailed = 0;
      for (final row in weekResponse as List) {
        final s = row['status'] as String?;
        if (s == 'completed') weekCompleted++;
        if (s == 'failed') weekFailed++;
      }

      return Result.success({
        'day_completed': dayCompleted,
        'day_failed': dayFailed,
        'day_total': dayResponse.length,
        'week_completed': weekCompleted,
        'week_failed': weekFailed,
        'week_total': weekResponse.length,
      });
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleExecution>> triggerDryRun({
    required String automationId,
    required String projectId,
    required String organizationId,
    required String eventType,
    String? deviceId,
    String? sensorKey,
    dynamic value,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'automation-engine',
        body: {
          'event_type': eventType,
          'device_id': deviceId,
          'project_id': projectId,
          'organization_id': organizationId,
          'sensor_key': sensorKey,
          'value': value,
          'payload': payload ?? {},
          'dry_run': true,
          'automation_id': automationId,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['error'] != null) {
        return Result.failure(ServerFailure(data['error'] as String));
      }

      final executions = await getExecutions(
        automationId: automationId,
        pageSize: 1,
      );
      return await executions.when(
        success: (list) async {
          if (list.isNotEmpty) {
            return Result<RuleExecution>.success(list.first);
          }
          return Result<RuleExecution>.failure(
            const ServerFailure('Dry run completed but no execution found'),
          );
        },
        failure: (f) async => Result<RuleExecution>.failure(f),
      );
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final ruleExecutionRepositoryProvider = Provider<RuleExecutionRepository>((
  ref,
) {
  return RuleExecutionRepository(ref.watch(supabaseClientProvider));
});
