import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/rule_execution.dart';

class RuleEventService {
  final SupabaseClient _client;

  RuleEventService(this._client);

  Future<Result<List<RuleEvent>>> getEvents({
    required String projectId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await _client
          .from('rule_events')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .range(from, to);
      final events = (response as List)
          .map((e) => RuleEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(events);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<RuleEvent>>> getEventsByCorrelation(
    String correlationId,
  ) async {
    try {
      final response = await _client
          .from('rule_events')
          .select()
          .eq('correlation_id', correlationId)
          .order('created_at');
      final events = (response as List)
          .map((e) => RuleEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(events);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<RuleEvent>>> getEventsByDevice({
    required String deviceId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('rule_events')
          .select()
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .limit(limit);
      final events = (response as List)
          .map((e) => RuleEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(events);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> submitDryRun({
    required String automationId,
    required String eventType,
    String? deviceId,
    required String projectId,
    required String organizationId,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final response = await _client.functions.invoke(
        'automation-engine',
        body: {
          'event_type': eventType,
          'device_id': deviceId,
          'project_id': projectId,
          'organization_id': organizationId,
          'payload': payload,
          'dry_run': true,
          'automation_id': automationId,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['error'] != null) {
        return Result.failure(ServerFailure(data['error'] as String));
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> sendManualTrigger({
    required String automationId,
    required String projectId,
    required String organizationId,
    Map<String, dynamic>? payload,
    bool dryRun = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'automation-engine',
        body: {
          'event_type': 'manual_trigger',
          'project_id': projectId,
          'organization_id': organizationId,
          'payload': payload ?? {},
          'dry_run': dryRun,
          'automation_id': automationId,
        },
      );

      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['error'] != null) {
        return Result.failure(ServerFailure(data['error'] as String));
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final ruleEventServiceProvider = Provider<RuleEventService>((ref) {
  return RuleEventService(ref.watch(supabaseClientProvider));
});
