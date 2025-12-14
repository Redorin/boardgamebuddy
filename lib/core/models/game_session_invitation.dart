// lib/core/models/game_session_invitation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, rejected }

class GameSessionInvitation {
  final String id;
  final String inviterId;
  final String inviterName;
  final String inviterImage;
  final String inviteeId;
  final String gameId;
  final String gameName;
  final String gameImageUrl;
  final DateTime sessionDate;
  final String sessionTime;
  final String sessionLocation;
  final InvitationStatus status;
  final DateTime sentAt;

  GameSessionInvitation({
    required this.id,
    required this.inviterId,
    required this.inviterName,
    required this.inviterImage,
    required this.inviteeId,
    required this.gameId,
    required this.gameName,
    required this.gameImageUrl,
    required this.sessionDate,
    required this.sessionTime,
    required this.sessionLocation,
    this.status = InvitationStatus.pending,
    required this.sentAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviterImage': inviterImage,
      'inviteeId': inviteeId,
      'gameId': gameId,
      'gameName': gameName,
      'gameImageUrl': gameImageUrl,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'sessionTime': sessionTime,
      'sessionLocation': sessionLocation,
      'status': status.name,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory GameSessionInvitation.fromFirestore(
      DocumentSnapshot doc, Map<String, dynamic> data) {
    
    final sessionDateTimestamp = data['sessionDate'] as Timestamp?;
    final sentAtTimestamp = data['sentAt'] as Timestamp?;

    return GameSessionInvitation(
      id: doc.id,
      inviterId: data['inviterId'] as String? ?? 'Unknown ID',
      inviterName: data['inviterName'] as String? ?? 'Unknown Player',
      inviterImage: data['inviterImage'] as String? ?? '',
      inviteeId: data['inviteeId'] as String? ?? 'Unknown ID',
      gameId: data['gameId'] as String? ?? '0',
      gameName: data['gameName'] as String? ?? 'Unknown Game',
      gameImageUrl: data['gameImageUrl'] as String? ?? '',
      
      sessionDate: sessionDateTimestamp?.toDate() ?? DateTime.now(),
      sessionTime: data['sessionTime'] as String? ?? 'N/A',
      sessionLocation: data['sessionLocation'] as String? ?? 'Online',
      
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => InvitationStatus.pending,
      ),
      sentAt: sentAtTimestamp?.toDate() ?? DateTime.now(),
    );
  }
}