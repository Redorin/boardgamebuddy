// lib/services/player_profile_service.dart

import '../pages/player_finder.dart'; // Import PlayerDisplay and related types

class PlayerProfileService {
  // Mock data for user profiles (will later be replaced by Firestore data)
  static final Map<String, Map<String, dynamic>> _mockUserProfiles = {
    // Keys match player IDs/Emails returned by GameService
    'user1@example.com': {
      'displayName': 'StrategyGuru',
      'distance': 2.5,
      'isOnline': true,
      'lastActiveTimestamp': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    'user2@example.com': {
      'displayName': 'CardSharp',
      'distance': 8.1,
      'isOnline': false,
      'lastActiveTimestamp': DateTime.now().subtract(const Duration(hours: 3)),
    },
    'user3@example.com': {
      'displayName': 'TheWorkerPlacer',
      'distance': 1.2,
      'isOnline': true,
      'lastActiveTimestamp': DateTime.now().subtract(const Duration(minutes: 30)),
    },
    'user4@example.com': {
      'displayName': 'CoopQueen',
      'distance': 15.0,
      'isOnline': false,
      'lastActiveTimestamp': DateTime.now().subtract(const Duration(days: 1)),
    },
    // Add more mock users as needed...
  };

  // Function to create a full PlayerDisplay model by merging game data with profile data
  static PlayerDisplay createPlayerDisplay(
      String playerId, List<String> games) {
    
    // Look up the mock profile data using the player's ID/Email
    final mockData = _mockUserProfiles[playerId];
    
    // Fallback if profile data is missing
    if (mockData == null) {
      return PlayerDisplay(
        id: playerId,
        displayName: playerId.split('@').first,
        games: games,
        distance: 100.0, 
        isOnline: false,
        gamesOwned: games.length,
        lastActiveTimestamp: DateTime.fromMicrosecondsSinceEpoch(0), // Oldest possible time
      );
    }

    return PlayerDisplay(
      id: playerId,
      displayName: mockData['displayName'] as String,
      games: games,
      distance: mockData['distance'] as double,
      isOnline: mockData['isOnline'] as bool,
      gamesOwned: games.length, 
      lastActiveTimestamp: mockData['lastActiveTimestamp'] as DateTime,
    );
  }
}