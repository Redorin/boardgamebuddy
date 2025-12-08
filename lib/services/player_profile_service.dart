// lib/services/player_profile_service.dart (FIXED)
import '../pages/player_finder.dart'; 
import 'dart:math'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:geolocator/geolocator.dart'; 

class PlayerProfileService {

  static PlayerDisplay createPlayerDisplay(
      String playerId, 
      List<String> games, 
      Map<String, dynamic> profileData, 
      Position? userCurrentPosition) {
    
    // 1. Basic Info Extraction
    final displayName = profileData['displayName'] as String? ?? playerId.split('@').first;
    // 🛑 FIX 1: Extract profileImage
    final profileImage = profileData['profileImage'] as String? ?? ''; 
    // 🛑 FIX 2: Extract preferredGenres
    final preferredGenres = (profileData['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];

    // 2. Activity Status
    final lastActiveTime = (profileData['updatedAt'] as Timestamp?)?.toDate() 
                           ?? (profileData['createdAt'] as Timestamp?)?.toDate() 
                           ?? DateTime.now().subtract(const Duration(hours: 2));
    final isOnline = DateTime.now().difference(lastActiveTime).inMinutes < 15;
    
    // 3. Distance Calculation
    double calculatedDistance = 999.0;
    if (userCurrentPosition != null && 
        profileData.containsKey('location') && 
        profileData['location'] is Map) {
      
      final targetLocation = profileData['location'];
      final targetLat = targetLocation['lat'] as double?;
      final targetLng = targetLocation['lng'] as double?;

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

    // 4. Return the fully populated object
    return PlayerDisplay(
      id: playerId,
      displayName: displayName,
      profileImage: profileImage,     // <--- Passed correctly now
      preferredGenres: preferredGenres, // <--- Passed correctly now
      games: games,
      distance: calculatedDistance,
      isOnline: isOnline,
      gamesOwned: games.length,
      lastActiveTimestamp: lastActiveTime,
    );
  }
}