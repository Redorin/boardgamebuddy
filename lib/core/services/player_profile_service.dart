// lib/core/services/player_profile_service.dart
import '../../features/player_finder/player_finder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfileService {
  // FIX: Signature now matches the requirements of the PlayerDisplay model
  static PlayerDisplay createPlayerDisplay(
    String playerId,
    Map<String, dynamic> profileData,
  ) {
    // --- Data Extraction ---
    final displayName =
        profileData['displayName'] as String? ?? playerId.split('@').first;

    // Extract required fields
    final profileImage = profileData['profileImage'] as String? ?? '';
    final preferredGenres =
        (profileData['preferredGenres'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    // Note: The count is now a cached field (number or double)
    final gamesOwned = (profileData['ownedGamesCount'] as num?)?.toInt() ?? 0;

    // --- Activity Status ---
    final lastActiveTime =
        (profileData['updatedAt'] as Timestamp?)?.toDate() ??
        (profileData['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.now().subtract(const Duration(hours: 2));
    final isOnline = DateTime.now().difference(lastActiveTime).inMinutes < 15;

    // --- Return the fully populated object ---
    return PlayerDisplay(
      id: playerId,
      displayName: displayName,
      profileImage: profileImage,
      preferredGenres: preferredGenres,
      isOnline: isOnline,
      gamesOwned: gamesOwned,
      lastActiveTimestamp: lastActiveTime,
    );
  }
}
