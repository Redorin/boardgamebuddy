// lib/pages/player_finder.dart (FIXED: READS PUBLIC PROFILES ONLY)
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/profile_service.dart';

// --- Data Models ---
class PlayerDisplay {
  final String id;
  final String displayName;
  final String profileImage; 
  final List<String> preferredGenres; // Uses genres instead of specific game titles
  final double distance;
  final bool isOnline;
  final int gamesOwned;
  final DateTime lastActiveTimestamp;

  PlayerDisplay({
    required this.id,
    required this.displayName,
    required this.profileImage,
    required this.preferredGenres,
    this.distance = 999.0,
    this.isOnline = false,
    this.gamesOwned = 0,
    required this.lastActiveTimestamp,
  });
}

enum SortOption { distance, active, games }

class PlayerFinderPage extends StatefulWidget {
  const PlayerFinderPage({Key? key}) : super(key: key);

  @override
  State<PlayerFinderPage> createState() => _PlayerFinderPageState();
}

class _PlayerFinderPageState extends State<PlayerFinderPage> {
  String _searchQuery = '';
  SortOption _sortBy = SortOption.distance;
  double _maxDistance = 50.0; 
  bool _showOnlineOnly = false;
  
  final TextEditingController _searchController = TextEditingController();
  Position? _userCurrentPosition;
  bool _isLocationLoading = true; 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _initializeLocation() async {
    ProfileService.updateCurrentLocation(); // Update own location
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _userCurrentPosition = position);
    } catch (e) {
      print("Location error: $e");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  // 💡 HELPER: Convert Firestore Document to PlayerDisplay
  PlayerDisplay _mapDocumentToPlayer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // 1. Basic Info
    final displayName = data['displayName'] as String? ?? 'Unknown Player';
    final profileImage = data['profileImage'] as String? ?? '';
    
    // 2. Genres & Count (Read directly from profile fields)
    final genres = (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final gamesCount = data['ownedGamesCount'] as int? ?? 0;

    // 3. Activity Status
    final lastActive = (data['updatedAt'] as Timestamp?)?.toDate() 
        ?? (data['createdAt'] as Timestamp?)?.toDate() 
        ?? DateTime(2000);
    final isOnline = DateTime.now().difference(lastActive).inMinutes < 15;

    // 4. Distance Calculation
    double distance = 999.0;
    if (_userCurrentPosition != null && data['location'] != null) {
      try {
        final loc = data['location'] as Map<String, dynamic>;
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        
        final meters = Geolocator.distanceBetween(
          _userCurrentPosition!.latitude, 
          _userCurrentPosition!.longitude, 
          lat, 
          lng
        );
        distance = meters / 1609.34; // Miles
      } catch (e) { /* Ignore bad location data */ }
    }

    return PlayerDisplay(
      id: doc.id,
      displayName: displayName,
      profileImage: profileImage,
      preferredGenres: genres,
      distance: distance,
      isOnline: isOnline,
      gamesOwned: gamesCount,
      lastActiveTimestamp: lastActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E2C), Color(0xFF0A0A1F)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search players...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // 💡 REVISED STREAM: Listen directly to 'users' collection
            // This works because your rules allow reading /users/{id}
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 1. Process Data
                  var players = snapshot.data!.docs
                      .map(_mapDocumentToPlayer)
                      // Filter out current user
                      .where((p) => p.id != FirebaseAuth.instance.currentUser?.uid) 
                      .toList();

                  // 2. Apply Filters
                  if (_searchQuery.isNotEmpty) {
                    players = players.where((p) => 
                      p.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.preferredGenres.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase()))
                    ).toList();
                  }
                  
                  if (_showOnlineOnly) {
                    players = players.where((p) => p.isOnline).toList();
                  }
                  
                  if (!_isLocationLoading && _maxDistance < 50) {
                     players = players.where((p) => p.distance <= _maxDistance).toList();
                  }

                  // 3. Sort
                  players.sort((a, b) {
                    switch (_sortBy) {
                      case SortOption.distance: return a.distance.compareTo(b.distance);
                      case SortOption.games: return b.gamesOwned.compareTo(a.gamesOwned);
                      case SortOption.active: return b.lastActiveTimestamp.compareTo(a.lastActiveTimestamp);
                    }
                  });

                  if (players.isEmpty) {
                    return const Center(child: Text("No players found.", style: TextStyle(color: Colors.white54)));
                  }

                  // 4. List View
                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) => _buildPlayerTile(players[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tile Widget ---
  Widget _buildPlayerTile(PlayerDisplay player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage: player.profileImage.isNotEmpty ? NetworkImage(player.profileImage) : null,
          child: player.profileImage.isEmpty 
              ? Text(player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?') 
              : null,
        ),
        title: Text(player.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Genres instead of Games list
            Text(
              player.preferredGenres.take(3).join(" • "), 
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  player.distance >= 999 ? "Unknown dist" : "${player.distance.toStringAsFixed(1)} mi",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.casino, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text("${player.gamesOwned} Games", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            )
          ],
        ),
        trailing: Icon(Icons.circle, size: 12, color: player.isOnline ? Colors.green : Colors.grey),
      ),
    );
  }
}