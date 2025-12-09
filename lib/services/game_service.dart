// lib/services/game_service.dart (UPDATED with Remove and Check methods)
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

  // 1. ADD GAMES BY ID (Write to Firestore - Unchanged)
  static Future<void> addGamesByIds(List<String> gameIds) async { 
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final collectionRef = userDocRef.collection('collection'); 
    final batch = _db.batch();

    for (String gameId in gameIds) {
      final docRef = collectionRef.doc(gameId);
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

  // 1.5. ✅ NEW: REMOVE GAME BY ID
  static Future<void> removeGameById(String gameId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    try {
      await userDocRef.collection('collection').doc(gameId).delete();
      print('Game ID $gameId removed from collection for UID: $currentUserId.');
    } catch (e) {
      print('Error removing game from collection: $e');
    }
  }

  // 2. GET USER'S GAMES (Read from Firestore - Stream - Unchanged)
  static Stream<List<BoardGame>> getUserCollectionGames() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);
    
    return userDocRef.collection('collection')
        .orderBy('added_at', descending: true)
        .snapshots() 
        .asyncMap((collectionSnapshot) async {
            
          final List<String> gameIds = collectionSnapshot.docs
              .map((doc) => doc.id) 
              .toList();

          if (gameIds.isEmpty) return [];

          final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = gameIds
              .map((id) => _db.collection('games').doc(id).get())
              .toList();

          final List<DocumentSnapshot<Map<String, dynamic>>> catalogSnapshots = await Future.wait(futures);

          return catalogSnapshots
              .where((snap) => snap.exists && snap.data() != null)
              .map((snap) => BoardGame.fromFirestore(snap.data()!))
              .toList();
        });
  }
  
  // 3. GET ALL CATALOG GAMES (Read from global collection - Unchanged)
  static Stream<List<BoardGame>> getAllCatalogGames() {
    return _db.collection('games')
        .orderBy('name')
        .snapshots() 
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BoardGame.fromFirestore(doc.data()))
              .toList();
        });
  }
  
  // 4. GET ALL PLAYERS (remains the same as before - Unchanged)
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
              .map((doc) => doc.id) 
              .toList();

          if (games.isNotEmpty) {
            playersData[username] = games;
          }
        }
        return playersData;
    });
  }
  
  // 5. ✅ NEW: Check if a game is owned (Used for the drawer state)
  static Stream<bool> isGameOwned(String gameId) {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value(false);

    return userDocRef.collection('collection').doc(gameId).snapshots().map((snapshot) {
      return snapshot.exists;
    }).handleError((e) {
        print("Error checking game ownership: $e");
        return false;
    });
  }
}