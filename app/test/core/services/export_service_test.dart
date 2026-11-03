import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/core/models/project_member.dart';
import 'package:nexioza/core/services/export_service.dart';

void main() {
  group('ExportService', () {
    final project = Project(
      id: 'proj-1',
      organizationId: 'org-1',
      name: 'Test Project',
      description: 'A test IoT project',
      icon: 'home',
      color: '#6366F1',
      version: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final members = [
      ProjectMember(
        projectId: 'proj-1',
        userId: 'u1',
        role: 'owner',
        createdAt: DateTime(2026),
        displayName: 'Alice',
      ),
      ProjectMember(
        projectId: 'proj-1',
        userId: 'u2',
        role: 'editor',
        createdAt: DateTime(2026),
        displayName: 'Bob',
      ),
    ];

    test('exportProject produces valid JSON', () {
      final json = ExportService.exportProject(project, members);
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['nexioza_export']['version'], 1);
      expect(data['nexioza_export']['type'], 'project');
      expect(data['project']['name'], 'Test Project');
      expect(data['members'], hasLength(2));
    });

    test('parseImport extracts project fields', () {
      final json = ExportService.exportProject(project, members);
      final result = ExportService.parseImport(json);

      expect(result, isNotNull);
      expect(result!.name, 'Test Project');
      expect(result.color, '#6366F1');
      expect(result.icon, 'home');
    });

    test('parseImport returns null for invalid JSON', () {
      expect(ExportService.parseImport('not json'), isNull);
      expect(ExportService.parseImport('{}'), isNull);
      expect(
        ExportService.parseImport('{"nexioza_export": {"type": "device"}}'),
        isNull,
      );
    });

    test('export round-trip preserves data', () {
      final exported = ExportService.exportProject(project, members);
      final parsed = ExportService.parseImport(exported);
      expect(parsed!.name, project.name);
      expect(parsed.description, project.description);
      expect(parsed.color, project.color);
      expect(parsed.icon, project.icon);
    });
  });
}
