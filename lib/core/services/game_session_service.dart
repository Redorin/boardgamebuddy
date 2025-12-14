// lib/core/services/game_session_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_session_invitation.dart';

class GameSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference _invitationsRef =
      FirebaseFirestore.instance.collection('game_invitations');

  Future<void> sendGameInvitation({
    required String inviteeId,
    required String inviteeName,
    required String inviteeImage,
    required String gameId,
    required String gameName,
    required String gameImageUrl,
    required DateTime date,
    required String time,
    required String location,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final inviterDoc = await _firestore.collection('users').doc(currentUserId).get();
    final inviterData = inviterDoc.data();
    final inviterName = inviterData?['displayName'] as String? ?? 'A Friend';
    final inviterImage = inviterData?['profileImage'] as String? ?? '';

    final invitation = GameSessionInvitation(
      id: '',
      inviterId: currentUserId,
      inviterName: inviterName,
      inviterImage: inviterImage,
      inviteeId: inviteeId,
      gameId: gameId,
      gameName: gameName,
      gameImageUrl: gameImageUrl,
      sessionDate: date,
      sessionTime: time,
      sessionLocation: location,
      status: InvitationStatus.pending,
      sentAt: DateTime.now(),
    );

    await _invitationsRef.add(invitation.toFirestore());
  }

  Stream<List<GameSessionInvitation>> getIncomingInvitationsStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _invitationsRef
        .where('inviteeId', isEqualTo: currentUserId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameSessionInvitation.fromFirestore(doc, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> respondToInvitation(
      String invitationId, InvitationStatus status) async {
    await _invitationsRef.doc(invitationId).update({
      'status': status.name,
    });
  }
}