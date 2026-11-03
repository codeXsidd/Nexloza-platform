import 'package:nexioza/core/models/invitation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationRepository {
  InvitationRepository(this._client);
  final SupabaseClient _client;

  Future<List<Invitation>> getMyInvitations() async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return [];
    final data = await _client
        .from('invitations')
        .select()
        .eq('invited_email', email)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return data.map((e) => Invitation.fromJson(e)).toList();
  }

  Future<List<Invitation>> getEntityInvitations({
    required String entityType,
    required String entityId,
  }) async {
    final data = await _client
        .from('invitations')
        .select()
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);
    return data.map((e) => Invitation.fromJson(e)).toList();
  }

  Future<void> createInvitation({
    required String entityType,
    required String entityId,
    required String email,
    required String role,
  }) async {
    await _client.rpc<void>(
      'create_invitation',
      params: {
        '_entity_type': entityType,
        '_entity_id': entityId,
        '_email': email,
        '_role': role,
      },
    );
  }

  Future<void> acceptInvitation(String token) async {
    await _client.rpc<void>('accept_invitation', params: {'_token': token});
  }

  Future<void> rejectInvitation(String token) async {
    await _client.rpc<void>('reject_invitation', params: {'_token': token});
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _client.rpc<void>(
      'cancel_invitation',
      params: {'_invitation_id': invitationId},
    );
  }
}
