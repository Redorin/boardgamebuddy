// lib/services/profile_service.dart (UPDATED WITH FRIEND SYSTEM)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:convert';

class ProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference? _getUserDocRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _db.collection('users').doc(userId);
  }

  // 1. SAVE ONBOARDING DATA 
  static Future<void> saveOnboardingData({
    required String username,
    required List<String> preferredGenres,
  }) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    try {
      await userDocRef.set({
        'displayName': username,
        'preferredGenres': preferredGenres,
        'onboardingComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving onboarding data: $e");
    }
  }
  
  // 2. SAVE PROFILE EDITS 
  static Future<void> saveProfileEdits({
    required String displayName,
    required String aboutMe,
    required List<String> preferredGenres,
    required String topGenre,
    required String profileImage, 
    required List<Map<String, dynamic>> favoriteGames, 
  }) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;

    try {
      await userDocRef.update({ 
        'displayName': displayName,
        'aboutMe': aboutMe,
        'preferredGenres': preferredGenres,
        'topGenre': topGenre,
        'favoriteGames': favoriteGames, 
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Profile edits saved successfully.");
    } catch (e) {
      print("Error saving profile edits: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        await userDocRef.set({
          'displayName': displayName,
          'aboutMe': aboutMe,
          'preferredGenres': preferredGenres,
          'topGenre': topGenre,
          'favoriteGames': favoriteGames,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // 3. STREAM USER PROFILE (Own Profile)
  static Stream<Map<String, dynamic>> getUserProfileStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({});
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? (snapshot.data() ?? {}) : {};
    });
  }
  
  // 💡 NEW: 3.5. STREAM PROFILE BY ID (For viewing other players)
  static Stream<Map<String, dynamic>> getProfileStreamById(String userId) {
    if (userId.isEmpty) return Stream.value({});
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? (snapshot.data() ?? {}) : {};
    });
  }
  
  // 4. Fetch Multiple Profiles
  static Future<Map<String, Map<String, dynamic>>> getProfilesByIds(List<String> profileIds) async {
    if (profileIds.isEmpty) return {};
    final profilesData = <String, Map<String, dynamic>>{};
    try {
      for (String id in profileIds) {
        final docSnapshot = await _db.collection('users').doc(id).get();
        if (docSnapshot.exists) {
          profilesData[id] = docSnapshot.data() ?? {};
        }
      }
      return profilesData;
    } catch (e) {
      return {};
    }
  }

  // 5. Update Location
  static Future<void> updateCurrentLocation() async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; 

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await userDocRef.update({
        'location': {'lat': position.latitude, 'lng': position.longitude},
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), 
      });
    } catch (e) {
      print('Location update failed: $e');
    }
  }

  // 6. Get Owned Games Count
  static Future<int> getOwnedGamesCount() async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return 0;
    try {
      final snapshot = await userDocRef.collection('collection').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // 💡 NEW: 7. ADD FRIEND
  static Future<void> addFriend(String friendId, String displayName, String profileImage) async {
    // 1. Get current user ID safely
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("Error: No authenticated user found.");
      return;
    }
    
    // 2. Validate inputs
    if (friendId.isEmpty) {
       print("Error: Friend ID is empty.");
       return;
    }

    final userDocRef = _db.collection('users').doc(userId);
    
    try {
      // 3. Write to the subcollection
      await userDocRef.collection('friends').doc(friendId).set({
        'id': friendId,
        'displayName': displayName,
        'profileImage': profileImage,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding friend: $e");
    }
  }

  // 8. REMOVE FRIEND
  static Future<void> removeFriend(String friendId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    try {
      await userDocRef.collection('friends').doc(friendId).delete();
    } catch (e) {
      print("Error removing friend: $e");
    }
  }

  // 9. CHECK IF FRIEND (Stream)
  static Stream<bool> isFriend(String friendId) {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value(false);
    
    return userDocRef.collection('friends').doc(friendId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  // 10. GET FRIENDS LIST STREAM
  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return Stream.value([]);
    
    return userDocRef.collection('friends')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }
}
