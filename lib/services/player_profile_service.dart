// lib/services/player_profile_service.dart
import '../pages/player_finder.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:geolocator/geolocator.dart'; 

class PlayerProfileService {

  // FIX: Signature now matches the requirements of the PlayerDisplay model
  static PlayerDisplay createPlayerDisplay(
      String playerId, 
      Map<String, dynamic> profileData, 
      Position? userCurrentPosition) {
    
    // --- Data Extraction ---
    final displayName = profileData['displayName'] as String? ?? playerId.split('@').first;
    
    // Extract required fields
    final profileImage = profileData['profileImage'] as String? ?? ''; 
    final preferredGenres = (profileData['preferredGenres'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    // Note: The count is now a cached field (number or double)
    final gamesOwned = (profileData['ownedGamesCount'] as num?)?.toInt() ?? 0;

    // --- Activity Status ---
    final lastActiveTime = (profileData['updatedAt'] as Timestamp?)?.toDate() 
                           ?? (profileData['createdAt'] as Timestamp?)?.toDate() 
                           ?? DateTime.now().subtract(const Duration(hours: 2));
    final isOnline = DateTime.now().difference(lastActiveTime).inMinutes < 15;
    
    // --- Distance Calculation ---
    double calculatedDistance = 999.0;
    if (userCurrentPosition != null && 
        profileData.containsKey('location') && 
        profileData['location'] is Map) {
      
      final targetLocation = profileData['location'];
      final targetLat = (targetLocation['lat'] as num?)?.toDouble();
      final targetLng = (targetLocation['lng'] as num?)?.toDouble();

      if (targetLat != null && targetLng != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          userCurrentPosition.latitude,
          userCurrentPosition.longitude,
          targetLat,
          targetLng,
        );
        calculatedDistance = distanceInMeters / 1609.34;
      }
    } 

    // --- Return the fully populated object ---
    return PlayerDisplay(
      id: playerId,
      displayName: displayName,
      profileImage: profileImage,     
      preferredGenres: preferredGenres, 
      distance: calculatedDistance,
      isOnline: isOnline,
      gamesOwned: gamesOwned,
      lastActiveTimestamp: lastActiveTime,
    );
  }
}