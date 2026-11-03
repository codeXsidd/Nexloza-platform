import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/core/models/project_category.dart';
import 'package:nexioza/core/models/project_member.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectRepository {
  ProjectRepository(this._client);
  final SupabaseClient _client;

  Future<List<Project>> getProjects() async {
    final data = await _client
        .from('projects')
        .select('*, project_members(user_id, role), organizations(name)')
        .eq('is_template', false)
        .order('created_at', ascending: false);
    return data.map((e) => Project.fromJson(e)).toList();
  }

  Future<Project?> getProject(String projectId) async {
    final data = await _client
        .from('projects')
        .select('*, project_members(user_id, role), organizations(name)')
        .eq('id', projectId)
        .maybeSingle();
    if (data == null) return null;
    return Project.fromJson(data);
  }

  Future<List<Project>> getTemplates() async {
    final data = await _client.from('project_templates').select().order('name');
    return data.map((e) => Project.fromJson(e)).toList();
  }

  Future<List<ProjectCategory>> getCategories() async {
    final data = await _client
        .from('project_categories')
        .select()
        .order('label');
    return data.map((e) => ProjectCategory.fromJson(e)).toList();
  }

  Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    final data = await _client
        .from('project_members')
        .select('*, profiles(display_name, avatar_url)')
        .eq('project_id', projectId)
        .order('created_at');
    return data.map((e) => ProjectMember.fromJson(e)).toList();
  }

  Future<String> createProject({
    required String organizationId,
    required String name,
    String description = '',
    String? categoryId,
    String icon = 'folder',
    String color = '#0891B2',
  }) async {
    final result = await _client.rpc<String>(
      'create_project',
      params: {
        '_organization_id': organizationId,
        '_name': name,
        '_description': description,
        '_category_id': categoryId,
        '_icon': icon,
        '_color': color,
      },
    );
    return result;
  }

  Future<String> createProjectFromTemplate({
    required String organizationId,
    required String templateId,
    required String name,
    String description = '',
  }) async {
    final result = await _client.rpc<String>(
      'create_project_from_template',
      params: {
        '_organization_id': organizationId,
        '_template_id': templateId,
        '_name': name,
        '_description': description,
      },
    );
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
    await _client.rpc<void>(
      'update_project',
      params: {
        '_project_id': projectId,
        '_expected_version': expectedVersion,
        '_name': name,
        '_description': description,
        '_icon': icon,
        '_color': color,
      },
    );
  }

  Future<void> deleteProject(String projectId) async {
    await _client.rpc<void>(
      'delete_project',
      params: {'_project_id': projectId},
    );
  }

  Future<String> duplicateProject({
    required String organizationId,
    required Project source,
    required String name,
  }) async {
    return createProject(
      organizationId: organizationId,
      name: name,
      description: source.description ?? '',
      categoryId: source.categoryId,
      icon: source.icon,
      color: source.color,
    );
  }
}
