// lib/services/profile_service.dart (FINAL, FULLY DEFINED FOR FRIEND SYSTEM)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart'; 

class ProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DateTime? _lastSuccessfulLocationUpdate;

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
        'ownedGamesCount': 0, 
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

  // 3. STREAM USER PROFILE (Own Profile)
  static Stream<Map<String, dynamic>> getUserProfileStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({});
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? (snapshot.data() ?? {}) : {};
    });
  }
  
  // 3.5. STREAM PROFILE BY ID (For viewing other players)
  static Stream<Map<String, dynamic>> getProfileStreamById(String userId) {
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
    if (_lastSuccessfulLocationUpdate != null && 
        DateTime.now().difference(_lastSuccessfulLocationUpdate!).inMinutes < 5) {
      print('Location update skipped: too soon.');
      return; 
    }
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

      _lastSuccessfulLocationUpdate = DateTime.now();
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

  // Helper to get the friends subcollection reference
  static CollectionReference? _getFriendsCollectionRef() {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return null;
    return userDocRef.collection('friends');
  }

  // 💡 7. SEND FRIEND REQUEST
  static Future<void> sendFriendRequest(String targetId) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null || targetId.isEmpty) return;

    // 💡 FIX: Fetch current user's (sender's) profile details from Firestore
    final senderDoc = await _db.collection('users').doc(senderId).get();
    final senderData = senderDoc.data();
    if (senderData == null) return;
    
    final senderName = senderData['displayName'] as String? ?? 'Anonymous User';
    final senderImage = senderData['profileImage'] as String? ?? '';

    final targetRequestRef = _db.collection('users').doc(targetId).collection('friendRequests').doc(senderId);

    try {
      await targetRequestRef.set({
        'senderId': senderId,
        'senderName': senderName, // Now from internal fetch
        'senderImage': senderImage, // Now from internal fetch
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending friend request: $e");
    }
  }

  // 💡 8. CHECK IF REQUEST IS PENDING (Called isRequestSent in UI)
  static Stream<bool> isRequestSent(String targetId) {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null || targetId.isEmpty) return Stream.value(false);

    return _db.collection('users').doc(targetId).collection('friendRequests').doc(senderId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  // 💡 9. ACCEPT FRIEND REQUEST
  static Future<void> acceptFriendRequest(String senderId, String senderName, String senderImage) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final batch = _db.batch();
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final senderUserRef = _db.collection('users').doc(senderId);

    // 1. DELETE the request from the current user's (receiver's) subcollection
    batch.delete(currentUserRef.collection('friendRequests').doc(senderId));

    // 2. ADD the sender to the current user's 'friends' list
    batch.set(currentUserRef.collection('friends').doc(senderId), {
      'id': senderId,
      'displayName': senderName,
      'profileImage': senderImage,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // 3. ADD the current user (receiver) to the sender's 'friends' list
    final currentUserSnapshot = await currentUserRef.get();
    final currentUserName = currentUserSnapshot.data()?['displayName'] ?? 'User';
    final currentUserImage = currentUserSnapshot.data()?['profileImage'] ?? '';
    
    batch.set(senderUserRef.collection('friends').doc(currentUserId), {
      'id': currentUserId,
      'displayName': currentUserName,
      'profileImage': currentUserImage,
      'addedAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } catch (e) {
      print("Error accepting friend request: $e");
    }
  }

  // 💡 10. REMOVE FRIEND (Used to remove friend OR decline request)
  static Future<void> removeFriend(String friendId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;
    
    final batch = _db.batch();
    
    // 1. Attempt to delete from the current user's friendRequests (declining)
    batch.delete(userDocRef.collection('friendRequests').doc(friendId));
    
    // 2. Attempt to delete from the current user's friends list (removing)
    batch.delete(userDocRef.collection('friends').doc(friendId));

    // 3. Attempt to delete myself from their friends list (removing from both sides)
    final otherUserRef = _db.collection('users').doc(friendId);
    // Note: Use a try-catch for the batch.commit if this specific line throws issues in Web
    batch.delete(otherUserRef.collection('friends').doc(_auth.currentUser!.uid));

    try {
      await batch.commit();
    } catch (e) {
      print("Error removing friend/declining request: $e");
    }
  }


  // 💡 11. CHECK IF FRIEND (Used to toggle button on read-only profile)
  static Stream<bool> isFriend(String friendId) {
    final friendsRef = _getFriendsCollectionRef();
    if (friendsRef == null) return Stream.value(false);
    
    return friendsRef.doc(friendId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  // 💡 12. GET INCOMING REQUESTS STREAM
  static Stream<List<Map<String, dynamic>>> getIncomingRequestsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _db.collection('users').doc(userId).collection('friendRequests')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        });
  }
  
  // 💡 13. GET FRIENDS LIST STREAM
  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final friendsRef = _getFriendsCollectionRef();
    if (friendsRef == null) return Stream.value([]);
    
    return friendsRef
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        });
  }
}