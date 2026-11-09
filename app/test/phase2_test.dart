import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/organizations/domain/entities/organization_entity.dart';
import 'package:nexloza/features/invitations/domain/entities/invitation_entity.dart';
import 'package:nexloza/shared/models/app_user.dart';
import 'package:nexloza/core/services/offline_sync_service.dart';
import 'package:nexloza/routing/route_names.dart';

void main() {
  group('AppUser', () {
    final json = {
      'id': 'user-1',
      'email': 'test@example.com',
      'full_name': 'Test User',
      'avatar_url': null,
      'phone': '+1234567890',
      'bio': 'A test user',
      'timezone': 'America/New_York',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('fromJson creates correct instance', () {
      final user = AppUser.fromJson(json);
      expect(user.id, 'user-1');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.phone, '+1234567890');
      expect(user.bio, 'A test user');
      expect(user.timezone, 'America/New_York');
    });

    test('displayName returns fullName when available', () {
      final user = AppUser.fromJson(json);
      expect(user.displayName, 'Test User');
    });

    test('displayName falls back to email prefix', () {
      final user = AppUser.fromJson({...json, 'full_name': null});
      expect(user.displayName, 'test');
    });

    test('copyWith updates fields', () {
      final user = AppUser.fromJson(json);
      final updated = user.copyWith(fullName: 'New Name', bio: 'New bio');
      expect(updated.fullName, 'New Name');
      expect(updated.bio, 'New bio');
      expect(updated.email, 'test@example.com');
      expect(updated.phone, '+1234567890');
    });

    test('toJson serializes correctly', () {
      final user = AppUser.fromJson(json);
      final serialized = user.toJson();
      expect(serialized['full_name'], 'Test User');
      expect(serialized['phone'], '+1234567890');
      expect(serialized['bio'], 'A test user');
      expect(serialized['timezone'], 'America/New_York');
    });

    test('defaults timezone to UTC when not provided', () {
      final minimalJson = {
        'id': 'user-2',
        'email': 'min@example.com',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final user = AppUser.fromJson(minimalJson);
      expect(user.timezone, 'UTC');
    });
  });

  group('Organization', () {
    final json = {
      'id': 'org-1',
      'name': 'Test Org',
      'description': 'A test organization',
      'logo_url': null,
      'created_by': 'user-1',
      'settings': {'theme': 'dark'},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('fromJson creates correct instance', () {
      final org = Organization.fromJson(json);
      expect(org.id, 'org-1');
      expect(org.name, 'Test Org');
      expect(org.description, 'A test organization');
      expect(org.createdBy, 'user-1');
      expect(org.settings, {'theme': 'dark'});
    });

    test('toJson serializes correctly', () {
      final org = Organization.fromJson(json);
      final serialized = org.toJson();
      expect(serialized['name'], 'Test Org');
      expect(serialized['description'], 'A test organization');
      expect(serialized.containsKey('id'), false);
    });

    test('handles null settings', () {
      final org = Organization.fromJson({...json, 'settings': null});
      expect(org.settings, isEmpty);
    });
  });

  group('OrgRole', () {
    test('fromString parses all roles', () {
      expect(OrgRole.fromString('owner'), OrgRole.owner);
      expect(OrgRole.fromString('admin'), OrgRole.admin);
      expect(OrgRole.fromString('member'), OrgRole.member);
      expect(OrgRole.fromString('viewer'), OrgRole.viewer);
    });

    test('fromString defaults to viewer for unknown', () {
      expect(OrgRole.fromString('unknown'), OrgRole.viewer);
    });

    test('canManage is true for owner and admin', () {
      expect(OrgRole.owner.canManage, true);
      expect(OrgRole.admin.canManage, true);
      expect(OrgRole.member.canManage, false);
      expect(OrgRole.viewer.canManage, false);
    });

    test('canEdit is true for owner, admin, and member', () {
      expect(OrgRole.owner.canEdit, true);
      expect(OrgRole.admin.canEdit, true);
      expect(OrgRole.member.canEdit, true);
      expect(OrgRole.viewer.canEdit, false);
    });

    test('isOwner is only true for owner', () {
      expect(OrgRole.owner.isOwner, true);
      expect(OrgRole.admin.isOwner, false);
      expect(OrgRole.member.isOwner, false);
      expect(OrgRole.viewer.isOwner, false);
    });

    test('displayName returns correct labels', () {
      expect(OrgRole.owner.displayName, 'Owner');
      expect(OrgRole.admin.displayName, 'Admin');
      expect(OrgRole.member.displayName, 'Member');
      expect(OrgRole.viewer.displayName, 'Viewer');
    });
  });

  group('OrgMember', () {
    test('fromJson creates correct instance with profile join', () {
      final member = OrgMember.fromJson({
        'id': 'mem-1',
        'organization_id': 'org-1',
        'user_id': 'user-1',
        'role': 'admin',
        'invited_by': 'user-0',
        'joined_at': '2026-01-01T00:00:00Z',
        'profiles': {'email': 'admin@test.com', 'full_name': 'Admin User'},
      });
      expect(member.role, OrgRole.admin);
      expect(member.userEmail, 'admin@test.com');
      expect(member.userName, 'Admin User');
      expect(member.displayName, 'Admin User');
    });

    test('displayName falls back to email then userId', () {
      final memberWithEmail = OrgMember.fromJson({
        'id': 'mem-2',
        'organization_id': 'org-1',
        'user_id': 'user-2',
        'role': 'member',
        'joined_at': '2026-01-01T00:00:00Z',
        'profiles': {'email': 'user@test.com', 'full_name': null},
      });
      expect(memberWithEmail.displayName, 'user@test.com');

      final memberNoProfile = OrgMember.fromJson({
        'id': 'mem-3',
        'organization_id': 'org-1',
        'user_id': 'user-3',
        'role': 'viewer',
        'joined_at': '2026-01-01T00:00:00Z',
      });
      expect(memberNoProfile.displayName, 'user-3');
    });
  });

  group('InvitationType', () {
    test('fromString parses correctly', () {
      expect(
        InvitationType.fromString('organization'),
        InvitationType.organization,
      );
      expect(InvitationType.fromString('project'), InvitationType.project);
    });

    test('fromString defaults to organization for unknown', () {
      expect(InvitationType.fromString('bogus'), InvitationType.organization);
    });
  });

  group('InvitationStatus', () {
    test('fromString parses all statuses', () {
      expect(InvitationStatus.fromString('pending'), InvitationStatus.pending);
      expect(
        InvitationStatus.fromString('accepted'),
        InvitationStatus.accepted,
      );
      expect(
        InvitationStatus.fromString('declined'),
        InvitationStatus.declined,
      );
      expect(InvitationStatus.fromString('expired'), InvitationStatus.expired);
      expect(
        InvitationStatus.fromString('cancelled'),
        InvitationStatus.cancelled,
      );
    });

    test('fromString defaults to pending for unknown', () {
      expect(InvitationStatus.fromString('bogus'), InvitationStatus.pending);
    });

    test('isPending returns correct value', () {
      expect(InvitationStatus.pending.isPending, true);
      expect(InvitationStatus.accepted.isPending, false);
      expect(InvitationStatus.declined.isPending, false);
    });

    test('displayName returns correct labels', () {
      expect(InvitationStatus.pending.displayName, 'Pending');
      expect(InvitationStatus.accepted.displayName, 'Accepted');
      expect(InvitationStatus.declined.displayName, 'Declined');
      expect(InvitationStatus.expired.displayName, 'Expired');
      expect(InvitationStatus.cancelled.displayName, 'Cancelled');
    });
  });

  group('Invitation', () {
    final futureDate = DateTime.now().add(const Duration(days: 7));
    final pastDate = DateTime.now().subtract(const Duration(days: 1));

    final json = {
      'id': 'inv-1',
      'invitation_type': 'organization',
      'organization_id': 'org-1',
      'project_id': null,
      'invited_email': 'invitee@test.com',
      'invited_user_id': null,
      'invited_by': 'user-1',
      'role': 'member',
      'status': 'pending',
      'message': 'Join our team!',
      'expires_at': futureDate.toIso8601String(),
      'responded_at': null,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'organizations': {'name': 'Test Org'},
      'projects': null,
      'inviter:profiles': {'full_name': 'Admin User'},
    };

    test('fromJson creates correct instance', () {
      final invite = Invitation.fromJson(json);
      expect(invite.id, 'inv-1');
      expect(invite.type, InvitationType.organization);
      expect(invite.organizationId, 'org-1');
      expect(invite.invitedEmail, 'invitee@test.com');
      expect(invite.role, 'member');
      expect(invite.status, InvitationStatus.pending);
      expect(invite.message, 'Join our team!');
      expect(invite.organizationName, 'Test Org');
      expect(invite.inviterName, 'Admin User');
    });

    test('targetName returns organization name', () {
      final invite = Invitation.fromJson(json);
      expect(invite.targetName, 'Test Org');
    });

    test('targetName returns project name for project invitations', () {
      final projectJson = {
        ...json,
        'invitation_type': 'project',
        'organization_id': null,
        'project_id': 'proj-1',
        'organizations': null,
        'projects': {'name': 'My IoT Project'},
      };
      final invite = Invitation.fromJson(projectJson);
      expect(invite.targetName, 'My IoT Project');
    });

    test('canRespond is true for pending non-expired invitations', () {
      final invite = Invitation.fromJson(json);
      expect(invite.canRespond, true);
    });

    test('canRespond is false for expired invitations', () {
      final expiredJson = {...json, 'expires_at': pastDate.toIso8601String()};
      final invite = Invitation.fromJson(expiredJson);
      expect(invite.canRespond, false);
    });

    test('canRespond is false for non-pending invitations', () {
      final acceptedJson = {...json, 'status': 'accepted'};
      final invite = Invitation.fromJson(acceptedJson);
      expect(invite.canRespond, false);
    });

    test('isExpired returns correct value', () {
      final invite = Invitation.fromJson(json);
      expect(invite.isExpired, false);

      final expired = Invitation.fromJson({
        ...json,
        'expires_at': pastDate.toIso8601String(),
      });
      expect(expired.isExpired, true);
    });
  });

  group('PendingOperation', () {
    test('fromJson and toJson roundtrip', () {
      final op = PendingOperation(
        id: 'op-1',
        table: 'profiles',
        method: 'update',
        data: {'full_name': 'Test'},
        filters: {'id': 'user-1'},
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      final jsonStr = jsonEncode(op.toJson());
      final decoded = PendingOperation.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );

      expect(decoded.id, 'op-1');
      expect(decoded.table, 'profiles');
      expect(decoded.method, 'update');
      expect(decoded.data['full_name'], 'Test');
      expect(decoded.filters?['id'], 'user-1');
      expect(decoded.retryCount, 0);
    });

    test('incrementRetry increments count', () {
      final op = PendingOperation(
        id: 'op-1',
        table: 'devices',
        method: 'insert',
        data: {'name': 'Device 1'},
        createdAt: DateTime.now(),
      );
      final retried = op.incrementRetry();
      expect(retried.retryCount, 1);
      expect(retried.id, op.id);
      expect(retried.table, op.table);

      final retriedAgain = retried.incrementRetry();
      expect(retriedAgain.retryCount, 2);
    });

    test('handles null filters', () {
      final op = PendingOperation(
        id: 'op-2',
        table: 'telemetry',
        method: 'insert',
        data: {'value': 42},
        createdAt: DateTime.now(),
      );
      final json = op.toJson();
      expect(json['filters'], isNull);
      final decoded = PendingOperation.fromJson(json);
      expect(decoded.filters, isNull);
    });
  });

  group('RouteNames Phase 2', () {
    test('has organization routes', () {
      expect(RouteNames.organizations, 'organizations');
      expect(RouteNames.createOrganization, 'createOrganization');
      expect(RouteNames.organizationDetail, 'organizationDetail');
    });

    test('has invitations route', () {
      expect(RouteNames.invitations, 'invitations');
    });

    test('has all existing routes unchanged', () {
      expect(RouteNames.home, 'home');
      expect(RouteNames.projects, 'projects');
      expect(RouteNames.devices, 'devices');
      expect(RouteNames.automations, 'automations');
      expect(RouteNames.profile, 'profile');
      expect(RouteNames.settings, 'settings');
      expect(RouteNames.notifications, 'notifications');
    });
  });
}
