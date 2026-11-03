import 'package:flutter_test/flutter_test.dart';
import 'package:nexioza/core/models/invitation.dart';
import 'package:nexioza/core/models/organization.dart';
import 'package:nexioza/core/models/organization_member.dart';
import 'package:nexioza/core/models/profile.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/core/models/project_category.dart';
import 'package:nexioza/core/models/project_member.dart';

void main() {
  group('Profile', () {
    test('fromJson creates valid profile', () {
      final json = {
        'id': 'user-123',
        'display_name': 'Test User',
        'avatar_url': 'https://example.com/avatar.png',
        'version': 2,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final profile = Profile.fromJson(json);
      expect(profile.id, 'user-123');
      expect(profile.displayName, 'Test User');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.version, 2);
    });

    test('copyWith creates modified copy', () {
      final profile = Profile(
        id: '1',
        displayName: 'Old',
        version: 1,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final updated = profile.copyWith(displayName: 'New');
      expect(updated.displayName, 'New');
      expect(updated.id, '1');
    });

    test('toJson round-trips correctly', () {
      final json = {
        'id': 'u1',
        'display_name': 'Alice',
        'avatar_url': null,
        'version': 1,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      };
      final profile = Profile.fromJson(json);
      final output = profile.toJson();
      expect(output['id'], 'u1');
      expect(output['display_name'], 'Alice');
    });
  });

  group('Organization', () {
    test('fromJson parses organization with members', () {
      final json = {
        'id': 'org-1',
        'name': 'My Org',
        'owner_id': 'user-1',
        'version': 1,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'organization_members': [
          {'user_id': 'user-1', 'role': 'owner'},
          {'user_id': 'user-2', 'role': 'member'},
        ],
      };
      final org = Organization.fromJson(json);
      expect(org.name, 'My Org');
      expect(org.memberCount, 2);
      expect(org.memberRole, 'owner');
    });
  });

  group('OrganizationMember', () {
    test('fromJson with profile join', () {
      final json = {
        'organization_id': 'org-1',
        'user_id': 'user-1',
        'role': 'admin',
        'created_at': '2026-01-01T00:00:00Z',
        'profiles': {'display_name': 'Admin User', 'avatar_url': null},
      };
      final member = OrganizationMember.fromJson(json);
      expect(member.displayName, 'Admin User');
      expect(member.isAdmin, true);
      expect(member.isOwner, false);
    });
  });

  group('Project', () {
    test('fromJson creates valid project', () {
      final json = {
        'id': 'proj-1',
        'organization_id': 'org-1',
        'name': 'IoT Hub',
        'description': 'Smart home project',
        'category_id': 'cat-1',
        'icon': 'home',
        'color': '#6366F1',
        'is_template': false,
        'version': 3,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'project_members': [
          {'user_id': 'u1', 'role': 'owner'},
        ],
        'organizations': {'name': 'My Org'},
      };
      final project = Project.fromJson(json);
      expect(project.name, 'IoT Hub');
      expect(project.color, '#6366F1');
      expect(project.organizationName, 'My Org');
      expect(project.memberCount, 1);
    });

    test('toExport includes essential fields', () {
      final project = Project(
        id: '1',
        organizationId: 'org1',
        name: 'Test',
        description: 'Desc',
        icon: 'folder',
        color: '#0891B2',
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final export = project.toExport();
      expect(export['name'], 'Test');
      expect(export['export_version'], 1);
      expect(export.containsKey('exported_at'), true);
    });
  });

  group('ProjectMember', () {
    test('role helpers work correctly', () {
      final owner = ProjectMember(
        projectId: 'p1',
        userId: 'u1',
        role: 'owner',
        createdAt: DateTime.now(),
      );
      expect(owner.isOwner, true);
      expect(owner.canManage, true);
      expect(owner.canEdit, true);

      final viewer = ProjectMember(
        projectId: 'p1',
        userId: 'u2',
        role: 'viewer',
        createdAt: DateTime.now(),
      );
      expect(viewer.isViewer, true);
      expect(viewer.canManage, false);
      expect(viewer.canEdit, false);

      final editor = ProjectMember(
        projectId: 'p1',
        userId: 'u3',
        role: 'editor',
        createdAt: DateTime.now(),
      );
      expect(editor.canEdit, true);
      expect(editor.canManage, false);
    });
  });

  group('ProjectCategory', () {
    test('fromJson creates valid category', () {
      final json = {'id': 'cat-1', 'label': 'Smart Home', 'icon': 'home'};
      final cat = ProjectCategory.fromJson(json);
      expect(cat.id, 'cat-1');
      expect(cat.label, 'Smart Home');
      expect(cat.icon, 'home');
    });
  });

  group('Invitation', () {
    test('fromJson creates valid invitation', () {
      final json = {
        'id': 'inv-1',
        'entity_type': 'organization',
        'entity_id': 'org-1',
        'invited_email': 'test@example.com',
        'role': 'member',
        'status': 'pending',
        'expires_at': '2026-12-31T00:00:00Z',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final inv = Invitation.fromJson(json);
      expect(inv.invitedEmail, 'test@example.com');
      expect(inv.isForOrganization, true);
      expect(inv.isForProject, false);
      expect(inv.isPending, true);
    });

    test('isExpired detects expired invitations', () {
      final expired = Invitation(
        id: '1',
        entityType: 'organization',
        entityId: 'org-1',
        invitedEmail: 'test@test.com',
        role: 'member',
        status: 'pending',
        expiresAt: DateTime(2020),
        createdAt: DateTime(2019),
      );
      expect(expired.isExpired, true);

      final valid = Invitation(
        id: '2',
        entityType: 'project',
        entityId: 'proj-1',
        invitedEmail: 'test@test.com',
        role: 'editor',
        status: 'pending',
        expiresAt: DateTime(2030),
        createdAt: DateTime(2026),
      );
      expect(valid.isExpired, false);
      expect(valid.isForProject, true);
    });
  });
}
