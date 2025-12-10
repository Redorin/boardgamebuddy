// lib/services/game_service.dart (UPDATED with Data Caching Optimization)
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

  // 1. ADD GAMES BY ID (UPDATED to fetch and cache full game data)
  static Future<void> addGamesByIds(List<String> gameIds) async { 
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final collectionRef = userDocRef.collection('collection'); 
    final batch = _db.batch();

    // 💡 OPTIMIZATION STEP 1: Fetch the full game data from the global '/games' collection ONCE.
    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = gameIds
        .map((id) => _db.collection('games').doc(id).get())
        .toList();
        
    final List<DocumentSnapshot<Map<String, dynamic>>> catalogSnapshots = await Future.wait(futures);
    
    int gamesSuccessfullyAdded = 0;

    for (final snap in catalogSnapshots) {
      if (snap.exists && snap.data() != null) {
        final gameData = BoardGame.fromFirestore(snap.data()!); 
        final docRef = collectionRef.doc(gameData.id);
        
        // 💡 OPTIMIZATION STEP 2: Write the full, rich game data map into the subcollection.
        // This makes future reads of the collection cheap (1 read per game instead of 2).
        batch.set(docRef, gameData.toFirestore()..['added_at'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true));
        
        gamesSuccessfullyAdded++;
      }
    }

    // Update the cached counter for the main user document
    batch.update(userDocRef, {
      'ownedGamesCount': FieldValue.increment(gamesSuccessfullyAdded.toDouble())
    });

    try {
      await batch.commit();
      print('$gamesSuccessfullyAdded games added to collection for UID: $currentUserId.');
    } catch (e) {
      print('Error adding games to collection: $e');
    }
  }

  // 1.5. REMOVE GAME BY ID (Remains the same)
  static Future<void> removeGameById(String gameId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final batch = _db.batch();
    
    // 1. Delete the game document from the subcollection
    batch.delete(userDocRef.collection('collection').doc(gameId));
    
    // 2. Decrement the ownedGamesCount field on the main user document
    batch.update(userDocRef, {
      'ownedGamesCount': FieldValue.increment(-1.0)
    });
    
    try {
      await batch.commit();
      print('Game ID $gameId removed from collection for UID: $currentUserId.');
    } catch (e) {
      print('Error removing game from collection: $e');
    }
  }

  // 2. GET USER'S GAMES (OPTIMIZED - Reads directly from cached subcollection data)
  static Stream<List<BoardGame>> getUserCollectionGames() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);
    
    // 💡 OPTIMIZATION: Now just reads the subcollection once and maps the data.
    // This is a single stream read for all games in the collection.
    return userDocRef.collection('collection')
        .orderBy('added_at', descending: true)
        .snapshots() 
        .map((collectionSnapshot) { // Changed from asyncMap to map
          
          return collectionSnapshot.docs
              // Maps the document data directly, as the full game object is now cached here.
              .map((doc) => BoardGame.fromFirestore(doc.data()))
              .toList();
        });
  }
  
  // 3. GET ALL CATALOG GAMES (Remains the same)
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
  
  // 4. CHECK IF A GAME IS OWNED (Remains the same)
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