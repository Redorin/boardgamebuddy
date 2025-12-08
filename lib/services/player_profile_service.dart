// lib/services/player_profile_service.dart
import '../pages/player_finder.dart'; 
import 'dart:math'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:geolocator/geolocator.dart'; // <--- NEW IMPORT

class PlayerProfileService {

  static PlayerDisplay createPlayerDisplay(
      String playerId, List<String> games, 
      Map<String, dynamic> profileData, 
      Position? userCurrentPosition) { // <--- Accepts the current user's Position
    
    // --- Data Extraction from Firestore Document ---
    
    final displayName = profileData['displayName'] as String? ?? playerId.split('@').first;
    final lastActiveTime = (profileData['updatedAt'] as Timestamp?)?.toDate() 
                           ?? (profileData['createdAt'] as Timestamp?)?.toDate() 
                           ?? DateTime.now().subtract(const Duration(hours: 2));
    final isOnline = DateTime.now().difference(lastActiveTime).inMinutes < 15;
    
    double calculatedDistance;
    
    // --- DISTANCE CALCULATION LOGIC ---
    if (userCurrentPosition != null && 
        profileData.containsKey('location') && 
        profileData['location'] is Map) {
      
      final targetLocation = profileData['location'];
      final targetLat = targetLocation['lat'] as double?;
      final targetLng = targetLocation['lng'] as double?;

      if (targetLat != null && targetLng != null) {
        // Calculate distance in meters, then convert to miles
        final distanceInMeters = Geolocator.distanceBetween(
          userCurrentPosition.latitude,
          userCurrentPosition.longitude,
          targetLat,
          targetLng,
        );
        // Convert meters to miles (1609.34 meters per mile)
        calculatedDistance = distanceInMeters / 1609.34;
      } else {
        // Fallback for corrupt location data
        calculatedDistance = 999.0;
      }
    } else {
      // Fallback: If no location data for current user or target
      // Use the large fallback number to push non-localized users to the end of the list
      calculatedDistance = 999.0; 
    }
    // -----------------------------------

    if (profileData.isEmpty) {
      return PlayerDisplay(
        id: playerId,
        displayName: displayName,
        games: games,
        distance: 100.0, 
        isOnline: false, 
        gamesOwned: games.length,
        lastActiveTimestamp: DateTime.fromMicrosecondsSinceEpoch(0),
      );
    }
    
    return PlayerDisplay(
      id: playerId,
      displayName: displayName,
      games: games,
      distance: calculatedDistance, // Use REAL calculated distance
      isOnline: isOnline,
      gamesOwned: games.length, 
      lastActiveTimestamp: lastActiveTime, 
    );
  }
}