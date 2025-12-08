// lib/services/game_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; 

class GameService {
  // Get the Firestore instance for database access
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ADD GAME (Write to Firestore)
  // Saves the game name to a subcollection under the user's username (key).
  static Future<void> addGame(String username, String game) async {
    if (username.isEmpty) {
      print("Error: Username is empty. Cannot add game.");
      return;
    }
    
    // Define the path: 'users/{username}/collection/{documentId}'
    // We use the game name (lowercase) as the document ID to prevent duplicates.
    final documentId = game.toLowerCase().trim();
    
    final collectionRef = _db
        .collection('users')
        .doc(username) // The username (or email) is the main document key
        .collection('collection');

    try {
      await collectionRef.doc(documentId).set({
        'name': game, // Store the original name
        'added_at': FieldValue.serverTimestamp()
      });
      print('Game "$game" added to collection for $username.');
    } catch (e) {
      print('Error adding game to collection: $e');
    }
  }

  // 2. GET GAMES (Listen for real-time updates from Firestore)
  // This is the core change: it returns a Stream, not a static List.
  static Stream<List<String>> getGamesStream(String username) {
    if (username.isEmpty) {
      return Stream.value([]); // Return an empty stream if username is missing
    }
    
    // Listen to the subcollection for changes
    return _db
        .collection('users')
        .doc(username)
        .collection('collection')
        .orderBy('added_at', descending: true) // Order games by time added
        .snapshots() // Get the Stream of QuerySnapshots (real-time updates)
        .map((snapshot) {
          // Map each document Snapshot to its 'name' field (String)
          return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
        });
  }
  
  // 3. GET ALL PLAYERS (Firestore version of getAllPlayers)
  // Used by the PlayerFinderPage
  static Stream<Map<String, List<String>>> getAllPlayersStream() {
    // Listen to all user documents in the 'users' collection
    return _db.collection('users').snapshots().asyncMap((usersSnapshot) async {
      final Map<String, List<String>> playersData = {};

      for (var userDoc in usersSnapshot.docs) {
        final username = userDoc.id;
        
        // For each user, fetch their 'collection' subcollection once
        final gamesSnapshot = await _db
            .collection('users')
            .doc(username)
            .collection('collection')
            .get();

        // Map the collection documents to a list of game names
        final List<String> games = gamesSnapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();

        if (games.isNotEmpty) {
          playersData[username] = games;
        }
      }
      return playersData;
    });
  }
}