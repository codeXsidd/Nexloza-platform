import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/result.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/alarm_configuration_entity.dart';

class AlarmConfigRepository {
  final Ref _ref;

  AlarmConfigRepository(this._ref);

  Future<Result<List<AlarmConfiguration>>> getConfigurations(
      String projectId) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarm_configurations')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      final configs = (response as List)
          .map((j) => AlarmConfiguration.fromJson(j))
          .toList();
      return Result.success(configs);
    } catch (e) {
      return Result.failure(
          ServerFailure('Failed to load alarm configurations: $e'));
    }
  }

  Future<Result<AlarmConfiguration>> createConfiguration(
      Map<String, dynamic> data) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarm_configurations')
          .insert(data)
          .select()
          .single();
      return Result.success(AlarmConfiguration.fromJson(response));
    } catch (e) {
      return Result.failure(
          ServerFailure('Failed to create alarm configuration: $e'));
    }
  }

  Future<Result<AlarmConfiguration>> updateConfiguration(
      String id, Map<String, dynamic> data) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('alarm_configurations')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Result.success(AlarmConfiguration.fromJson(response));
    } catch (e) {
      return Result.failure(
          ServerFailure('Failed to update alarm configuration: $e'));
    }
  }

  Future<Result<void>> deleteConfiguration(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('alarm_configurations').delete().eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          ServerFailure('Failed to delete alarm configuration: $e'));
    }
  }

  Future<Result<void>> toggleConfiguration(String id, bool enabled) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase
          .from('alarm_configurations')
          .update({'is_enabled': enabled}).eq('id', id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          ServerFailure('Failed to toggle alarm configuration: $e'));
    }
  }
}

final alarmConfigRepositoryProvider = Provider<AlarmConfigRepository>((ref) {
  return AlarmConfigRepository(ref);
});
