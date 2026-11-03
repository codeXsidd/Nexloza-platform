import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectRepository {
  ProjectRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getProjects() async {
    final data = await _client
        .from('projects')
        .select('*, project_members(user_id, role)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data =
        await _client.from('project_categories').select().order('label');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> createProject({
    required String organizationId,
    required String name,
    String description = '',
    String? categoryId,
    String icon = 'folder',
    String color = '#0891B2',
  }) async {
    final result = await _client.rpc<String>('create_project', params: {
      '_organization_id': organizationId,
      '_name': name,
      '_description': description,
      '_category_id': categoryId,
      '_icon': icon,
      '_color': color,
    });
    return result;
  }

  Future<void> updateProject({
    required String projectId,
    required int expectedVersion,
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    await _client.rpc<void>('update_project', params: {
      '_project_id': projectId,
      '_expected_version': expectedVersion,
      '_name': name,
      '_description': description,
      '_icon': icon,
      '_color': color,
    });
  }

  Future<void> deleteProject(String projectId) async {
    await _client.rpc<void>('delete_project', params: {'_project_id': projectId});
  }
}
