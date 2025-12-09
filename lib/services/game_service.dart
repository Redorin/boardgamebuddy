// lib/services/game_service.dart (UPDATED with Counter Caching Fix)
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

  // 1. ADD GAMES BY ID (Write to Firestore - UPDATED for Counter Caching)
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

    // 💡 QUOTA FIX: Increment the ownedGamesCount field on the main user document
    batch.update(userDocRef, {
      'ownedGamesCount': FieldValue.increment(gameIds.length.toDouble()) // Use toDouble() for increment
    });

    try {
      await batch.commit();
      print('${gameIds.length} games added to collection for UID: $currentUserId.');
    } catch (e) {
      print('Error adding games to collection: $e');
    }
  }

  // 1.5. REMOVE GAME BY ID (UPDATED for Counter Caching)
  static Future<void> removeGameById(String gameId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final batch = _db.batch();
    
    // 1. Delete the game document from the subcollection
    batch.delete(userDocRef.collection('collection').doc(gameId));
    
    // 2. 💡 QUOTA FIX: Decrement the ownedGamesCount field on the main user document
    batch.update(userDocRef, {
      'ownedGamesCount': FieldValue.increment(-1.0) // Use -1.0 for decrement
    });
    
    try {
      await batch.commit();
      print('Game ID $gameId removed from collection for UID: $currentUserId.');
    } catch (e) {
      print('Error removing game from collection: $e');
    }
  }

  // 2. GET USER'S GAMES (Read from Firestore - Stream)
  static Stream<List<BoardGame>> getUserCollectionGames() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);
    
    // Note: This still maps collection IDs to games, which is correct and necessary 
    // for getting the *actual game data*. The quota fix targeted the *count* only.
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
  
  // 3. GET ALL CATALOG GAMES (Read from global collection)
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
  
  // 4. CHECK IF A GAME IS OWNED
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