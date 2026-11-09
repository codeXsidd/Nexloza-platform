import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/organization_entity.dart';

class OrganizationRepository {
  final SupabaseClient _client;

  OrganizationRepository(this._client);

  Future<Result<List<Organization>>> getOrganizations() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final memberRows = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', userId);
      final orgIds = (memberRows as List)
          .map((r) => r['organization_id'] as String)
          .toList();

      if (orgIds.isEmpty) return Result.success([]);

      final response = await _client
          .from('organizations')
          .select()
          .inFilter('id', orgIds)
          .order('created_at', ascending: false);
      final orgs = (response as List)
          .map((e) => Organization.fromJson(e))
          .toList();
      return Result.success(orgs);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Organization>> getOrganization(String id) async {
    try {
      final response = await _client
          .from('organizations')
          .select()
          .eq('id', id)
          .single();
      return Result.success(Organization.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Organization>> createOrganization({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client
          .from('organizations')
          .insert({
            'name': name,
            'description': description,
            'created_by': _client.auth.currentUser!.id,
          })
          .select()
          .single();
      return Result.success(Organization.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Organization>> updateOrganization(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('organizations')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Result.success(Organization.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteOrganization(String id) async {
    try {
      await _client.from('organizations').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<OrgMember>>> getMembers(String orgId) async {
    try {
      final response = await _client
          .from('organization_members')
          .select('*, profiles(email, full_name)')
          .eq('organization_id', orgId)
          .order('joined_at');
      final members = (response as List)
          .map((e) => OrgMember.fromJson(e))
          .toList();
      return Result.success(members);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> removeMember(String orgId, String userId) async {
    try {
      await _client
          .from('organization_members')
          .delete()
          .eq('organization_id', orgId)
          .eq('user_id', userId);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> updateMemberRole(
    String orgId,
    String userId,
    OrgRole role,
  ) async {
    try {
      await _client
          .from('organization_members')
          .update({'role': role.name})
          .eq('organization_id', orgId)
          .eq('user_id', userId);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<OrgRole?>> getCurrentUserRole(String orgId) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('organization_members')
          .select('role')
          .eq('organization_id', orgId)
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return Result.success(null);
      return Result.success(OrgRole.fromString(response['role'] as String));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(supabaseClientProvider));
});
