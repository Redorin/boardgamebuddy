// lib/services/game_service.dart (UPDATED)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NEW IMPORT
import 'dart:async'; 

class GameService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Get the current user's secure UID
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid; 

  // --- Helper to get the base collection reference ---
  static DocumentReference? _getUserDocRef() {
    final userId = currentUserId;
    if (userId == null) {
      print("Error: User is not authenticated. Cannot get document reference.");
      return null;
    }
    // 💡 CORE FIX: Use the secure UID as the main document key
    return _db.collection('users').doc(userId); 
  }

  // 1. ADD GAME (Write to Firestore)
  // Removed 'username' parameter, relies on authenticated user.
  static Future<void> addGame(String game) async { 
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final documentId = game.toLowerCase().trim();
    final collectionRef = userDocRef.collection('collection'); // Path: users/{uid}/collection

    try {
      await collectionRef.doc(documentId).set({
        'name': game,
        'added_at': FieldValue.serverTimestamp()
      });
      print('Game "$game" added to collection for UID: $currentUserId.');
    } catch (e) {
      print('Error adding game to collection: $e');
    }
  }

  // 2. GET GAMES (Read from Firestore - Stream)
  // Removed 'username' parameter, relies on authenticated user.
  static Stream<List<String>> getGamesStream() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);
    
    // Listen to the subcollection for changes
    return userDocRef.collection('collection')
        .orderBy('added_at', descending: true)
        .snapshots() 
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
        });
  }
  
  // 3. GET ALL PLAYERS (Firestore Stream)
  // NOTE: This logic needs a complex change if you rely ONLY on UID security rules.
  // For now, we will revert this to the original implementation which uses email
  // but acknowledge that the security rule (Step 4 below) must be permissive for this function.
  // We cannot easily filter by UID here without changing the entire data structure.

  // Reverting to previous logic for this specific function (temp fix)
  static Stream<Map<String, List<String>>> getAllPlayersStream() {
    return _db.collection('users').snapshots().asyncMap((usersSnapshot) async {
      final Map<String, List<String>> playersData = {};

      for (var userDoc in usersSnapshot.docs) {
        final username = userDoc.id; // This is the email if you stuck to the original design
        
        final gamesSnapshot = await _db
            .collection('users')
            .doc(username)
            .collection('collection')
            .get();

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