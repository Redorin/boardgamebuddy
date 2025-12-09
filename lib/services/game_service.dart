// lib/services/game_service.dart (UPDATED)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'dart:async'; 
import '../models/board_game.dart'; 

class GameService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid; 

  static DocumentReference? _getUserDocRef() {
    final userId = currentUserId;
    if (userId == null) {
      print("Error: User is not authenticated. Cannot get document reference.");
      return null;
    }
    return _db.collection('users').doc(userId); 
  }

  // 1. ADD GAMES BY ID (Write to Firestore - New Logic)
  static Future<void> addGamesByIds(List<String> gameIds) async { 
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final collectionRef = userDocRef.collection('collection'); 

    // Use a Firestore Write Batch for atomic updates
    final batch = _db.batch();

    for (String gameId in gameIds) {
      // The document ID in the user's collection is now the official game ID
      final docRef = collectionRef.doc(gameId);
      
      // Store only the game ID and a timestamp in the user's collection
      batch.set(docRef, {
        'gameId': gameId,
        'added_at': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
      print('${gameIds.length} games added to collection for UID: $currentUserId.');
    } catch (e) {
      print('Error adding games to collection: $e');
    }
  }

  // 2. GET USER'S GAMES (Read from Firestore - Stream)
  // Returns a Stream of BoardGame objects by joining user collection data with catalog data
  static Stream<List<BoardGame>> getUserCollectionGames() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);
    
    // 1. Stream the user's collection (only containing game IDs)
    return userDocRef.collection('collection')
        .orderBy('added_at', descending: true)
        .snapshots() 
        .asyncMap((collectionSnapshot) async {
            
          final List<String> gameIds = collectionSnapshot.docs
              .map((doc) => doc.id) // Doc ID is the game ID
              .toList();

          if (gameIds.isEmpty) return [];

          // 2. Batch fetch the actual game data from the global 'games' collection using IDs
          final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = gameIds
              .map((id) => _db.collection('games').doc(id).get())
              .toList();

          final List<DocumentSnapshot<Map<String, dynamic>>> catalogSnapshots = await Future.wait(futures);

          // 3. Convert snapshots to BoardGame objects
          return catalogSnapshots
              .where((snap) => snap.exists && snap.data() != null)
              .map((snap) => BoardGame.fromFirestore(snap.data()!))
              .toList();
        });
  }
  
  // 3. GET ALL CATALOG GAMES (Read from global collection)
  static Stream<List<BoardGame>> getAllCatalogGames() {
    // This is a direct read from the public '/games' collection
    return _db.collection('games')
        .orderBy('name')
        .snapshots() 
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BoardGame.fromFirestore(doc.data()))
              .toList();
        });
  }
  
  // 4. GET ALL PLAYERS (remains the same as before)
  static Stream<Map<String, List<String>>> getAllPlayersStream() {
    return _db.collection('users').snapshots().asyncMap((usersSnapshot) async {
        final Map<String, List<String>> playersData = {};

        for (var userDoc in usersSnapshot.docs) {
          final username = userDoc.id;
          
          final gamesSnapshot = await _db
              .collection('users')
              .doc(username)
              .collection('collection')
              .get();

          final List<String> games = gamesSnapshot.docs
              .map((doc) => doc.id) // Now mapping the Game ID
              .toList();

          if (games.isNotEmpty) {
            playersData[username] = games;
          }
        }
        return playersData;
    });
  }
}