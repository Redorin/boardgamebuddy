// lib/core/services/game_service.dart
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

  /// ADD GAMES BY ID
  static Future<void> addGamesByIds(List<String> gameIds) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;

    final collectionRef = userDocRef.collection('collection');
    final batch = _db.batch();

    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = gameIds
        .map((id) => _db.collection('games').doc(id).get())
        .toList();

    final List<DocumentSnapshot<Map<String, dynamic>>> catalogSnapshots =
        await Future.wait(futures);

    int gamesSuccessfullyAdded = 0;

    for (final snap in catalogSnapshots) {
      if (snap.exists && snap.data() != null) {
        final gameData = BoardGame.fromFirestore(snap.data()!);
        final docRef = collectionRef.doc(gameData.id);

        batch.set(
          docRef,
          gameData.toFirestore()..['added_at'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true),
        );

        gamesSuccessfullyAdded++;
      }
    }

    // Update the cached counter for the main user document
    batch.update(userDocRef, {
      'ownedGamesCount': FieldValue.increment(
        gamesSuccessfullyAdded.toDouble(),
      ),
    });

    try {
      await batch.commit();
      print(
        '$gamesSuccessfullyAdded games added to collection for UID: $currentUserId.',
      );
    } catch (e) {
      print('Error adding games to collection: $e');
    }
  }

  /// REMOVE GAME BY ID (Updates favoriteGames list)
  static Future<void> removeGameById(String gameId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;

    // Fetch the user document to get the current favoriteGames array
    final userSnapshot = await userDocRef.get();
    final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};

    // Attempt to cast the stored list to the correct format (List<Map<String, dynamic>>)
    final currentFavorites =
        (userData['favoriteGames'] as List?)
            ?.map((item) => item as Map<String, dynamic>)
            .toList() ??
        [];

    // Filter the list to remove the game being deleted
    final newFavorites = currentFavorites
        .where((game) => game['id'] != gameId)
        .toList();

    final batch = _db.batch();

    // Delete the game document from the subcollection
    batch.delete(userDocRef.collection('collection').doc(gameId));

    // Decrement the ownedGamesCount field AND update the favoriteGames list
    batch.update(userDocRef, {
      'ownedGamesCount': FieldValue.increment(-1.0),
      'favoriteGames': newFavorites,
    });

    try {
      await batch.commit();
      print(
        'Game ID $gameId removed from collection and favorites for UID: $currentUserId.',
      );
    } catch (e) {
      print('Error removing game from collection: $e');
    }
  }

  /// GET USER'S GAMES (FIX: Pass doc.id to the factory for correct model creation)
  static Stream<List<BoardGame>> getUserCollectionGames() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);

    return userDocRef
        .collection('collection')
        // We rely on Firestore returning the data reliably without orderBy since we removed it in the last step.
        .snapshots()
        .map((collectionSnapshot) {
          return collectionSnapshot.docs
              .map((doc) {
                // IMPORTANT FIX: Manually merge the document ID into the data map
                final data = doc.data();
                data['id'] = doc.id; 
                return BoardGame.fromFirestore(data);
              })
              .toList();
        });
  }

  /// GET ALL CATALOG GAMES
  static Stream<List<BoardGame>> getAllCatalogGames() {
    return _db.collection('games').orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BoardGame.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// CHECK IF A GAME IS OWNED
  static Stream<bool> isGameOwned(String gameId) {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value(false);

    return userDocRef
        .collection('collection')
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
          return snapshot.exists;
        })
        .handleError((e) {
          print("Error checking game ownership: $e");
          return false;
        });
  }

  /// GET USER'S COLLECTION IDs
  static Stream<Set<String>> getUserCollectionIds() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value({});

    return userDocRef.collection('collection').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }
}