import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/result.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/escalation_policy_entity.dart';

class EscalationRepository {
  final Ref _ref;

  EscalationRepository(this._ref);

  Future<Result<List<EscalationPolicy>>> getPolicies(String projectId) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('escalation_policies')
          .select('*, escalation_stages(*)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      final policies = (response as List)
          .map((j) => EscalationPolicy.fromJson(j))
          .toList();
      return Result.success(policies);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to load escalation policies: $e'),
      );
    }
  }

  Future<Result<EscalationPolicy>> getPolicyById(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('escalation_policies')
          .select('*, escalation_stages(*)')
          .eq('id', id)
          .single();
      return Result.success(EscalationPolicy.fromJson(response));
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to load escalation policy: $e'),
      );
    }
  }

  Future<Result<EscalationPolicy>> createPolicy(
    Map<String, dynamic> data,
  ) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('escalation_policies')
          .insert(data)
          .select('*, escalation_stages(*)')
          .single();
      return Result.success(EscalationPolicy.fromJson(response));
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to create escalation policy: $e'),
      );
    }
  }

  Future<Result<EscalationPolicy>> updatePolicy(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('escalation_policies')
          .update(data)
          .eq('id', id)
          .select('*, escalation_stages(*)')
          .single();
      return Result.success(EscalationPolicy.fromJson(response));
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to update escalation policy: $e'),
      );
    }
  }

  Future<Result<void>> deletePolicy(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('escalation_policies').delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to delete escalation policy: $e'),
      );
    }
  }

  Future<Result<EscalationStage>> addStage(Map<String, dynamic> data) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('escalation_stages')
          .insert(data)
          .select()
          .single();
      return Result.success(EscalationStage.fromJson(response));
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to add escalation stage: $e'),
      );
    }
  }

  Future<Result<void>> updateStage(String id, Map<String, dynamic> data) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('escalation_stages').update(data).eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to update escalation stage: $e'),
      );
    }
  }

  Future<Result<void>> removeStage(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('escalation_stages').delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to remove escalation stage: $e'),
      );
    }
  }
}

final escalationRepositoryProvider = Provider<EscalationRepository>((ref) {
  return EscalationRepository(ref);
});
