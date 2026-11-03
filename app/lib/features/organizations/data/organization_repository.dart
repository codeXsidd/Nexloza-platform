import 'package:nexioza/core/models/organization.dart';
import 'package:nexioza/core/models/organization_member.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationRepository {
  OrganizationRepository(this._client);
  final SupabaseClient _client;

  Future<List<Organization>> getOrganizations() async {
    final data = await _client
        .from('organizations')
        .select('*, organization_members(user_id, role)')
        .order('created_at');
    return data.map((e) => Organization.fromJson(e)).toList();
  }

  Future<Organization?> getOrganization(String orgId) async {
    final data = await _client
        .from('organizations')
        .select('*, organization_members(user_id, role)')
        .eq('id', orgId)
        .maybeSingle();
    if (data == null) return null;
    return Organization.fromJson(data);
  }

  Future<String> createOrganization(String name) async {
    final result = await _client.rpc<String>(
      'create_organization',
      params: {'_name': name},
    );
    return result;
  }

  Future<void> updateOrganization({
    required String orgId,
    required int expectedVersion,
    required String name,
  }) async {
    await _client.rpc<void>(
      'update_organization',
      params: {
        '_org_id': orgId,
        '_expected_version': expectedVersion,
        '_name': name,
      },
    );
  }

  Future<void> deleteOrganization(String orgId) async {
    await _client.rpc<void>('delete_organization', params: {'_org_id': orgId});
  }

  Future<List<OrganizationMember>> getOrganizationMembers(String orgId) async {
    final data = await _client
        .from('organization_members')
        .select('*, profiles(display_name, avatar_url)')
        .eq('organization_id', orgId)
        .order('created_at');
    return data.map((e) => OrganizationMember.fromJson(e)).toList();
  }

  Future<void> transferOwnership(String orgId, String newOwnerId) async {
    await _client.rpc<void>(
      'transfer_org_ownership',
      params: {'_org_id': orgId, '_new_owner_id': newOwnerId},
    );
  }

  Future<void> updateMemberRole({
    required String entityType,
    required String entityId,
    required String targetUserId,
    required String newRole,
  }) async {
    await _client.rpc<void>(
      'update_member_role',
      params: {
        '_entity_type': entityType,
        '_entity_id': entityId,
        '_target_user_id': targetUserId,
        '_new_role': newRole,
      },
    );
  }

  Future<void> removeMember({
    required String entityType,
    required String entityId,
    required String targetUserId,
  }) async {
    await _client.rpc<void>(
      'remove_member',
      params: {
        '_entity_type': entityType,
        '_entity_id': entityId,
        '_target_user_id': targetUserId,
      },
    );
  }
}
