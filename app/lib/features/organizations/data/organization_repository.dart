import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationRepository {
  OrganizationRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getOrganizations() async {
    final data = await _client
        .from('organizations')
        .select('*, organization_members(user_id, role)')
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
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
    await _client.rpc<void>('update_organization', params: {
      '_org_id': orgId,
      '_expected_version': expectedVersion,
      '_name': name,
    });
  }

  Future<void> deleteOrganization(String orgId) async {
    await _client.rpc<void>('delete_organization', params: {'_org_id': orgId});
  }
}
