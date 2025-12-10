// lib/pages/player_finder.dart (FINAL: NAVIGATION & FILTER UI/LOGIC)
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart'; 
import '../services/profile_service.dart';
import 'read_only_profile_page.dart'; // 💡 NEW IMPORT for profile viewing

// --- Data Models (Unchanged) ---
class PlayerDisplay {
  final String id;
  final String displayName;
  final String profileImage; 
  final List<String> preferredGenres; 
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
    ProfileService.updateCurrentLocation(); 
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

  // 💡 HELPER: Convert Firestore Document to PlayerDisplay (Unchanged)
  PlayerDisplay _mapDocumentToPlayer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // 1. Basic Info
    final displayName = data['displayName'] as String? ?? 'Unknown Player';
    final profileImage = data['profileImage'] as String? ?? '';
    
    // 2. Genres & Count
    final genres = (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final gamesCount = (data['ownedGamesCount'] as num?)?.toInt() ?? 0;

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
        distance = meters / 1609.34; 
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

  // 💡 UI Helper for Filter Chip
  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFC0C0C0))),
      avatar: isSelected ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
      onPressed: onTap,
      backgroundColor: isSelected ? const Color(0xFF673AB7) : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? const Color(0xFF673AB7) : Colors.white.withOpacity(0.2)),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search players or genres...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // 💡 NEW: Filter and Sort Controls (Phase 2, Item 11)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap( // Using Wrap for clean horizontal spacing
                spacing: 8.0,
                children: [
                  // 1. Online Only Filter
                  _buildFilterChip(
                    label: 'Online Only',
                    isSelected: _showOnlineOnly,
                    onTap: () => setState(() => _showOnlineOnly = !_showOnlineOnly),
                  ),

                  // 2. Sort By Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SortOption>(
                        value: _sortBy,
                        dropdownColor: const Color(0xFF1E1E2C),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: SortOption.distance, child: Text('Sort: Closest')),
                          DropdownMenuItem(value: SortOption.active, child: Text('Sort: Most Active')),
                          DropdownMenuItem(value: SortOption.games, child: Text('Sort: Most Games')),
                        ],
                        onChanged: (SortOption? newValue) {
                          if (newValue != null) setState(() => _sortBy = newValue);
                        },
                      ),
                    ),
                  ),

                  // 3. Max Distance Slider (Only show if location is not loading)
                  if (!_isLocationLoading)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Max Distance: ${_maxDistance.toStringAsFixed(0)} mi', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Slider(
                            value: _maxDistance,
                            min: 5,
                            max: 100,
                            divisions: 19,
                            activeColor: Colors.deepPurpleAccent,
                            inactiveColor: Colors.white30,
                            onChanged: (double newValue) {
                              setState(() => _maxDistance = newValue);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Player List Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Query remains optimized: filter by users who completed setup
                stream: FirebaseFirestore.instance.collection('users')
                          //.where('onboardingComplete', isEqualTo: true)
                          .snapshots(),
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
                      .where((p) => p.id != FirebaseAuth.instance.currentUser?.uid) 
                      .toList();

                  // 2. Apply Filters (Local filtering based on UI controls)
                  if (_searchQuery.isNotEmpty) {
                    players = players.where((p) => 
                      p.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.preferredGenres.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase()))
                    ).toList();
                  }
                  
                  if (_showOnlineOnly) {
                    players = players.where((p) => p.isOnline).toList();
                  }
                  
                  // Filter by distance if location is available and slider is set low
                  if (!_isLocationLoading && _maxDistance < 100) {
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
                    return const Center(child: Text("No players found matching current filters.", style: TextStyle(color: Colors.white54)));
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

  // --- Tile Widget (Updated with Navigation) ---
  Widget _buildPlayerTile(PlayerDisplay player) {
    final bool hasProfileImage = player.profileImage.isNotEmpty;
    final String initials = player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // 💡 NEW: Navigation to ReadOnlyProfilePage (Phase 2, Item 10)
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadOnlyProfilePage(userId: player.id),
            ),
          );
        },
        // 🛑 FIX: Use CircleAvatar child with error handling for image loading
        leading: CircleAvatar(
          backgroundColor: hasProfileImage ? Colors.transparent : Colors.grey.shade700,
          radius: 24,
          child: hasProfileImage
              ? ClipOval(
                  child: Image.network(
                    player.profileImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    // Use errorBuilder to catch ImageCodecException and fallback
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    },
                  ),
                )
              // Fallback for empty URL
              : Center(
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
        ),
        title: Text(player.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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