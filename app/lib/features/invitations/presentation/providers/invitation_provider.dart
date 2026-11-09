import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invitation_repository.dart';
import '../../domain/entities/invitation_entity.dart';

class InvitationsNotifier extends AsyncNotifier<List<Invitation>> {
  @override
  Future<List<Invitation>> build() async {
    final repo = ref.read(invitationRepositoryProvider);
    final result = await repo.getMyInvitations();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<bool> acceptInvitation(String id) async {
    final repo = ref.read(invitationRepositoryProvider);
    final result = await repo.acceptInvitation(id);
    return result.when(
      success: (accepted) {
        if (accepted) ref.invalidateSelf();
        return accepted;
      },
      failure: (_) => false,
    );
  }

  Future<bool> declineInvitation(String id) async {
    final repo = ref.read(invitationRepositoryProvider);
    final result = await repo.declineInvitation(id);
    return result.when(
      success: (declined) {
        if (declined) ref.invalidateSelf();
        return declined;
      },
      failure: (_) => false,
    );
  }
}

final invitationsProvider =
    AsyncNotifierProvider<InvitationsNotifier, List<Invitation>>(
      InvitationsNotifier.new,
    );

final sentInvitationsProvider = FutureProvider<List<Invitation>>((ref) async {
  final repo = ref.read(invitationRepositoryProvider);
  final result = await repo.getSentInvitations();
  return result.when(success: (data) => data, failure: (_) => []);
});
