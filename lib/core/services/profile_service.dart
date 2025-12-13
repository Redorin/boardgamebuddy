import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference? _getUserDocRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _db.collection('users').doc(userId);
  }

  /// SAVE ONBOARDING DATA
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

  /// SAVE PROFILE EDITS
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

  /// STREAM USER PROFILE (Own Profile)
  static Stream<Map<String, dynamic>> getUserProfileStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({});
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? (snapshot.data() ?? {}) : {};
    });
  }

  /// STREAM PROFILE BY ID (For viewing other players)
  static Stream<Map<String, dynamic>> getProfileStreamById(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? (snapshot.data() ?? {}) : {};
    });
  }

  /// Fetch Multiple Profiles
  static Future<Map<String, Map<String, dynamic>>> getProfilesByIds(
    List<String> profileIds,
  ) async {
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

  /// Get Owned Games Count
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

  /// SEND FRIEND REQUEST
  static Future<void> sendFriendRequest(String targetId) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null || targetId.isEmpty) return;

    // Fetch current user's (sender's) profile details from Firestore
    final senderDoc = await _db.collection('users').doc(senderId).get();
    final senderData = senderDoc.data();
    if (senderData == null) return;

    final senderName = senderData['displayName'] as String? ?? 'Anonymous User';
    final senderImage = senderData['profileImage'] as String? ?? '';

    final targetRequestRef = _db
        .collection('users')
        .doc(targetId)
        .collection('friendRequests')
        .doc(senderId);

    try {
      await targetRequestRef.set({
        'senderId': senderId,
        'senderName': senderName,
        'senderImage': senderImage,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending friend request: $e");
    }
  }

  /// CHECK IF REQUEST IS PENDING
  static Stream<bool> isRequestSent(String targetId) {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null || targetId.isEmpty) return Stream.value(false);

    return _db
        .collection('users')
        .doc(targetId)
        .collection('friendRequests')
        .doc(senderId)
        .snapshots()
        .map((snapshot) {
          return snapshot.exists;
        });
  }

  /// ACCEPT FRIEND REQUEST
  static Future<void> acceptFriendRequest(
    String senderId,
    String senderName,
    String senderImage,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = _db.batch();
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final senderUserRef = _db.collection('users').doc(senderId);

    // DELETE the request from the current user's (receiver's) subcollection
    batch.delete(currentUserRef.collection('friendRequests').doc(senderId));

    // ADD the sender to the current user's 'friends' list
    batch.set(currentUserRef.collection('friends').doc(senderId), {
      'id': senderId,
      'displayName': senderName,
      'profileImage': senderImage,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // ADD the current user (receiver) to the sender's 'friends' list
    final currentUserSnapshot = await currentUserRef.get();
    final currentUserName =
        currentUserSnapshot.data()?['displayName'] ?? 'User';
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

  /// REMOVE FRIEND (Remove friend OR decline request)
  static Future<void> removeFriend(String friendId) async {
    final userDocRef = _getUserDocRef();
    if (userDocRef == null) return;

    final batch = _db.batch();

    // Attempt to delete from the current user's friendRequests (declining)
    batch.delete(userDocRef.collection('friendRequests').doc(friendId));

    // Attempt to delete from the current user's friends list (removing)
    batch.delete(userDocRef.collection('friends').doc(friendId));

    // Attempt to delete myself from their friends list (removing from both sides)
    final otherUserRef = _db.collection('users').doc(friendId);
    batch.delete(
      otherUserRef.collection('friends').doc(_auth.currentUser!.uid),
    );

    try {
      await batch.commit();
    } catch (e) {
      print("Error removing friend/declining request: $e");
    }
  }

  /// CHECK IF FRIEND
  static Stream<bool> isFriend(String friendId) {
    final friendsRef = _getFriendsCollectionRef();
    if (friendsRef == null) return Stream.value(false);

    return friendsRef.doc(friendId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  /// GET INCOMING REQUESTS STREAM
  static Stream<List<Map<String, dynamic>>> getIncomingRequestsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
  }

  /// GET FRIENDS LIST STREAM
  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final friendsRef = _getFriendsCollectionRef();
    if (friendsRef == null) return Stream.value([]);

    return friendsRef.orderBy('displayName').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }
}
