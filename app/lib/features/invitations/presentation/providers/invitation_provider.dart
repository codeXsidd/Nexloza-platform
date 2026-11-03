import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/core/models/invitation.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/invitations/data/invitation_repository.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository(ref.watch(supabaseClientProvider));
});

final myInvitationsProvider = FutureProvider<List<Invitation>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(invitationRepositoryProvider).getMyInvitations();
});

final entityInvitationsProvider =
    FutureProvider.family<
      List<Invitation>,
      ({String entityType, String entityId})
    >((ref, params) async {
      return ref
          .read(invitationRepositoryProvider)
          .getEntityInvitations(
            entityType: params.entityType,
            entityId: params.entityId,
          );
    });
