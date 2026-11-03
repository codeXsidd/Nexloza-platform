import 'dart:convert';

import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/core/models/project_member.dart';

class ExportService {
  static String exportProject(Project project, List<ProjectMember> members) {
    final data = {
      'nexioza_export': {
        'version': 1,
        'type': 'project',
        'exported_at': DateTime.now().toUtc().toIso8601String(),
      },
      'project': project.toExport(),
      'members': members
          .map((m) => {'role': m.role, 'display_name': m.displayName})
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static ({
    String name,
    String? description,
    String? categoryId,
    String icon,
    String color,
  })?
  parseImport(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final header = data['nexioza_export'] as Map<String, dynamic>?;
      if (header == null || header['type'] != 'project') return null;

      final project = data['project'] as Map<String, dynamic>?;
      if (project == null) return null;

      return (
        name: project['name'] as String? ?? 'Imported Project',
        description: project['description'] as String?,
        categoryId: project['category_id'] as String?,
        icon: project['icon'] as String? ?? 'folder',
        color: project['color'] as String? ?? '#0891B2',
      );
    } catch (_) {
      return null;
    }
  }
}
