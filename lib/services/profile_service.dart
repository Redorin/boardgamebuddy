// lib/services/profile_service.dart (COMPLETE CODE with Geolocation)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart'; // REQUIRED for location updates

class ProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference? _getUserDocRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("Error: User is not authenticated. Cannot get profile ref.");
      return null;
    }
    // Path: users/{uid}
    return _db.collection('users').doc(userId);
  }

  // 1. SAVE ONBOARDING DATA (Used by OnboardingPage)
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
      
      print("Onboarding data saved successfully for $username.");
    } catch (e) {
      print("Error saving onboarding data: $e");
    }
  }
  
  // 2. SAVE PROFILE EDITS (Used by ProfilePage to save username, bio, genres, etc.)
  static Future<void> saveProfileEdits({
    required String displayName,
    required String aboutMe,
    required List<String> preferredGenres,
    required String topGenre,
    required String profileImage, 
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving profile edits: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        await userDocRef.set({
          'displayName': displayName,
          'aboutMe': aboutMe,
          'preferredGenres': preferredGenres,
          'topGenre': topGenre,
          'profileImage': profileImage,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // 3. STREAM USER PROFILE DATA (for ProfilePage display)
  static Stream<Map<String, dynamic>> getUserProfileStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }

    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {};
      }
      return snapshot.data() ?? {};
    });
  }
  
  // 4. Fetch Multiple Profiles by ID (for Player Finder)
  static Future<Map<String, Map<String, dynamic>>> getProfilesByIds(
      List<String> profileIds) async {
    
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
      print("Error fetching multiple profiles: $e");
      return {};
    }
  }

  // 💡 NEW METHOD: 5. Handle Geolocation and Update Firestore
  static Future<void> updateCurrentLocation() async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    try {
      // 1. Check permissions and services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location service not enabled.");
        return;
      } 

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          print("Location permission permanently denied or denied.");
          return;
        }
      }

      // 2. Get current position (high accuracy for best results)
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. Update Firestore with new coordinates
      await userDocRef.update({
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), // Update 'updatedAt' for 'Online Now' heuristic
      });
      print('Location updated successfully: ${position.latitude}, ${position.longitude}');

    } catch (e) {
      print('Failed to get or update location: $e');
    }
  }
}