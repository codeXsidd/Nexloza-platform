import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/rule_graph.dart';
import '../domain/entities/rule_validation.dart';

class RuleAutomation {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final bool isEnabled;
  final int priority;
  final int cooldownSeconds;
  final int maxExecutionsPerHour;
  final RuleGraph? ruleGraph;
  final RuleStatus status;
  final int graphVersion;
  final DateTime? publishedAt;
  final String? publishedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RuleAutomation({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.isEnabled = true,
    this.priority = 0,
    this.cooldownSeconds = 60,
    this.maxExecutionsPerHour = 60,
    this.ruleGraph,
    this.status = RuleStatus.draft,
    this.graphVersion = 1,
    this.publishedAt,
    this.publishedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RuleAutomation.fromJson(Map<String, dynamic> json) {
    return RuleAutomation(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      cooldownSeconds: json['cooldown_seconds'] as int? ?? 60,
      maxExecutionsPerHour: json['max_executions_per_hour'] as int? ?? 60,
      ruleGraph: json['rule_graph'] != null
          ? RuleGraph.fromJson(json['rule_graph'] as Map<String, dynamic>)
          : null,
      status: RuleStatus.fromString(json['status'] as String? ?? 'draft'),
      graphVersion: json['graph_version'] as int? ?? 1,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      publishedBy: json['published_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class RuleRepository {
  final SupabaseClient _client;

  RuleRepository(this._client);

  Future<Result<List<RuleAutomation>>> getRules({
    String? projectId,
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client.from('automations').select();
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await query
          .order('updated_at', ascending: false)
          .range(from, to);
      final rules = (response as List)
          .map((e) => RuleAutomation.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(rules);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleAutomation>> getRule(String id) async {
    try {
      final response = await _client
          .from('automations')
          .select()
          .eq('id', id)
          .single();
      return Result.success(RuleAutomation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleAutomation>> createRule({
    required String projectId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client
          .from('automations')
          .insert({
            'project_id': projectId,
            'name': name,
            'description': description,
            'is_enabled': false,
            'status': 'draft',
            'graph_version': 1,
          })
          .select()
          .single();
      return Result.success(RuleAutomation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleAutomation>> saveGraph(
    String automationId,
    RuleGraph graph,
  ) async {
    try {
      final existing = await _client
          .from('automations')
          .select('graph_version')
          .eq('id', automationId)
          .single();
      final currentVersion = existing['graph_version'] as int? ?? 1;

      final response = await _client
          .from('automations')
          .update({
            'rule_graph': graph.toJson(),
            'graph_version': currentVersion + 1,
            'status': 'draft',
          })
          .eq('id', automationId)
          .select()
          .single();
      return Result.success(RuleAutomation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<ValidationError>>> validateRule(
    String automationId,
  ) async {
    try {
      final response = await _client
          .from('automations')
          .select('rule_graph')
          .eq('id', automationId)
          .single();

      final graphJson = response['rule_graph'] as Map<String, dynamic>?;
      if (graphJson == null) {
        return Result.success([
          const ValidationError(message: 'No rule graph defined'),
        ]);
      }

      final graph = RuleGraph.fromJson(graphJson);
      const validator = RuleGraphValidator();
      final errors = validator.validate(graph);

      if (errors.isEmpty) {
        await _client
            .from('automations')
            .update({'status': 'validated'})
            .eq('id', automationId);
      }

      return Result.success(errors);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleVersion>> publishRule(String automationId) async {
    try {
      final rule = await _client
          .from('automations')
          .select()
          .eq('id', automationId)
          .single();

      final status = rule['status'] as String? ?? 'draft';
      if (status != 'validated') {
        return Result.failure(
          const ValidationFailure('Rule must be validated before publishing'),
        );
      }

      final graphJson = rule['rule_graph'] as Map<String, dynamic>?;
      if (graphJson == null) {
        return Result.failure(const ValidationFailure('No rule graph defined'));
      }

      final userId = _client.auth.currentUser?.id;

      final latestVersion = await _client
          .from('rule_versions')
          .select('version_number')
          .eq('automation_id', automationId)
          .order('version_number', ascending: false)
          .limit(1);

      final nextVersion = (latestVersion as List).isNotEmpty
          ? ((latestVersion.first as Map)['version_number'] as int) + 1
          : 1;

      final now = DateTime.now().toIso8601String();

      final versionResponse = await _client
          .from('rule_versions')
          .insert({
            'automation_id': automationId,
            'version_number': nextVersion,
            'graph_snapshot': graphJson,
            'published_at': now,
            'published_by': userId,
          })
          .select()
          .single();

      await _client
          .from('automations')
          .update({
            'status': 'published',
            'published_at': now,
            'published_by': userId,
          })
          .eq('id', automationId);

      return Result.success(RuleVersion.fromJson(versionResponse));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> enableRule(String id) async {
    try {
      await _client
          .from('automations')
          .update({'status': 'enabled', 'is_enabled': true})
          .eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> disableRule(String id) async {
    try {
      await _client
          .from('automations')
          .update({'status': 'disabled', 'is_enabled': false})
          .eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> archiveRule(String id) async {
    try {
      await _client
          .from('automations')
          .update({'status': 'archived', 'is_enabled': false})
          .eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<RuleVersion>>> getVersionHistory(
    String automationId,
  ) async {
    try {
      final response = await _client
          .from('rule_versions')
          .select()
          .eq('automation_id', automationId)
          .order('version_number', ascending: false);
      final versions = (response as List)
          .map((e) => RuleVersion.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(versions);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteRule(String id) async {
    try {
      await _client.from('automations').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<RuleAutomation>> updateRuleInfo({
    required String id,
    String? name,
    String? description,
    int? cooldownSeconds,
    int? maxExecutionsPerHour,
    int? priority,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (cooldownSeconds != null) {
        updates['cooldown_seconds'] = cooldownSeconds;
      }
      if (maxExecutionsPerHour != null) {
        updates['max_executions_per_hour'] = maxExecutionsPerHour;
      }
      if (priority != null) updates['priority'] = priority;

      if (updates.isEmpty) {
        return await getRule(id);
      }

      final response = await _client
          .from('automations')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Result.success(RuleAutomation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final ruleRepositoryProvider = Provider<RuleRepository>((ref) {
  return RuleRepository(ref.watch(supabaseClientProvider));
});
