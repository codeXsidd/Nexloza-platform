import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/invitation_entity.dart';

class InvitationRepository {
  final SupabaseClient _client;

  InvitationRepository(this._client);

  Future<Result<List<Invitation>>> getMyInvitations() async {
    try {
      final response = await _client
          .from('invitations')
          .select(
            '*, organizations(name), projects(name), inviter:profiles!invited_by(full_name)',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final invitations = (response as List)
          .map((e) => Invitation.fromJson(e))
          .toList();
      return Result.success(invitations);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<Invitation>>> getSentInvitations() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('invitations')
          .select(
            '*, organizations(name), projects(name), inviter:profiles!invited_by(full_name)',
          )
          .eq('invited_by', userId)
          .order('created_at', ascending: false);
      final invitations = (response as List)
          .map((e) => Invitation.fromJson(e))
          .toList();
      return Result.success(invitations);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Invitation>> sendOrganizationInvitation({
    required String organizationId,
    required String email,
    required String role,
    String? message,
  }) async {
    try {
      final response = await _client
          .from('invitations')
          .insert({
            'invitation_type': 'organization',
            'organization_id': organizationId,
            'invited_email': email,
            'invited_by': _client.auth.currentUser!.id,
            'role': role,
            'message': message,
          })
          .select(
            '*, organizations(name), projects(name), inviter:profiles!invited_by(full_name)',
          )
          .single();
      return Result.success(Invitation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Invitation>> sendProjectInvitation({
    required String projectId,
    required String email,
    required String role,
    String? message,
  }) async {
    try {
      final response = await _client
          .from('invitations')
          .insert({
            'invitation_type': 'project',
            'project_id': projectId,
            'invited_email': email,
            'invited_by': _client.auth.currentUser!.id,
            'role': role,
            'message': message,
          })
          .select(
            '*, organizations(name), projects(name), inviter:profiles!invited_by(full_name)',
          )
          .single();
      return Result.success(Invitation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<bool>> acceptInvitation(String invitationId) async {
    try {
      final response = await _client.rpc(
        'accept_invitation',
        params: {'p_invitation_id': invitationId},
      );
      return Result.success(response as bool? ?? false);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<bool>> declineInvitation(String invitationId) async {
    try {
      final response = await _client.rpc(
        'decline_invitation',
        params: {'p_invitation_id': invitationId},
      );
      return Result.success(response as bool? ?? false);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> cancelInvitation(String invitationId) async {
    try {
      await _client.from('invitations').delete().eq('id', invitationId);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository(ref.watch(supabaseClientProvider));
});
