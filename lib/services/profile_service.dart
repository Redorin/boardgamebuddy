// lib/services/profile_service.dart (REQUIRED FILE)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart'; 

class ProfileService { // <--- THIS is the class the pages are looking for
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
        'ownedGamesCount': 0, // Initialize cached counter
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
        'profileImage': profileImage,
        'favoriteGames': favoriteGames, 
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Profile edits saved successfully.");
    } catch (e) {
      print("Error saving profile edits: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        // Handle case where document doesn't exist yet
        await userDocRef.set({
          'displayName': displayName,
          'aboutMe': aboutMe,
          'preferredGenres': preferredGenres,
          'topGenre': topGenre,
          'profileImage': profileImage,
          'favoriteGames': favoriteGames,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // 3. STREAM USER PROFILE 
  static Stream<Map<String, dynamic>> getUserProfileStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({});
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? (snapshot.data() ?? {}) : {};
    });
  }
  
  // 4. Fetch Multiple Profiles (Used for potential future friend list hydration)
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
}