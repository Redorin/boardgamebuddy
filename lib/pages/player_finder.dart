// lib/pages/player_finder.dart (UPDATED with FINAL SHIMMER SKELETON UI)
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart'; 
import 'package:shimmer/shimmer.dart'; // 💡 PACKAGE MUST BE INSTALLED
import '../services/profile_service.dart';
import 'read_only_profile_page.dart';

// --- Data Models (Keep these classes in your file) ---
class PlayerDisplay {
  final String id;
  final String displayName;
  final String profileImage; 
  final List<String> preferredGenres; 
  final double distance;
  final bool isOnline;
  final int gamesOwned;
  final DateTime lastActiveTimestamp;

  PlayerDisplay({required this.id, required this.displayName, required this.profileImage, required this.preferredGenres, this.distance = 999.0, this.isOnline = false, this.gamesOwned = 0, required this.lastActiveTimestamp});
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
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
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
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _userCurrentPosition = position);
    } catch (e) {
      print("Location error: $e");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  PlayerDisplay _mapDocumentToPlayer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final displayName = data['displayName'] as String? ?? 'Unknown';
    final profileImage = data['profileImage'] as String? ?? '';
    final genres = (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final gamesCount = (data['ownedGamesCount'] as num?)?.toInt() ?? 0;
    final lastActive = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    final isOnline = DateTime.now().difference(lastActive).inMinutes < 15;
    
    double distance = 999.0;
    if (_userCurrentPosition != null && data['location'] != null) {
      try {
        final loc = data['location'];
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        distance = Geolocator.distanceBetween(_userCurrentPosition!.latitude, _userCurrentPosition!.longitude, lat, lng) / 1609.34;
      } catch (e) {}
    }

    return PlayerDisplay(id: doc.id, displayName: displayName, profileImage: profileImage, preferredGenres: genres, distance: distance, isOnline: isOnline, gamesOwned: gamesCount, lastActiveTimestamp: lastActive);
  }

  // 💡 NEW: Skeleton Tile Widget (The core modern UI element)
  Widget _buildSkeletonTile() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF171A21), // Dark gray/blue base
      highlightColor: const Color(0xFF2A3F5F), // Lighter shimmer color
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const CircleAvatar(radius: 24, backgroundColor: Colors.black), // Skeleton Avatar
          title: Container(height: 10, width: 150, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5))), // Skeleton Title
          subtitle: Container(height: 8, width: 100, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5))), // Skeleton Subtitle
        ),
      ),
    );
  }

  // 💡 NEW: Skeleton List Builder
  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 6, // Show 6 placeholder tiles
      itemBuilder: (context, index) => _buildSkeletonTile(),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFC0C0C0))),
      avatar: isSelected ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
      onPressed: onTap,
      backgroundColor: isSelected ? const Color(0xFF673AB7) : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? const Color(0xFF673AB7) : Colors.white.withOpacity(0.2))),
    );
  }

  // 💡 MODIFIED: _buildFriendsList (Uses Skeleton)
  Widget _buildFriendsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ProfileService.getFriendsStream(),
      builder: (context, snapshot) {
        // 🛑 SHOW SKELETON WHILE WAITING
        if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonList();
        
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) return const Center(child: Text("You haven't added any friends yet.", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          itemCount: friends.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              color: const Color(0xFF171A21),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(friend['profileImage'] ?? '')),
                title: Text(friend['displayName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReadOnlyProfilePage(userId: friend['id'])));
                },
              ),
            );
          },
        );
      },
    );
  }
  
  // 💡 MODIFIED: _buildRequestsList (Uses Skeleton)
  Widget _buildRequestsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ProfileService.getIncomingRequestsStream(),
      builder: (context, snapshot) {
        // 🛑 SHOW SKELETON WHILE WAITING
        if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonList();
        
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) return const Center(child: Text("No incoming friend requests.", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          itemCount: requests.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final request = requests[index];
            final senderId = request['senderId'] as String? ?? '';
            final senderName = request['senderName'] as String? ?? 'Unknown User';
            final senderImage = request['senderImage'] as String? ?? '';

            return Card(
              color: const Color(0xFF171A21),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(senderImage)),
                title: Text(senderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Sent you a request", style: TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await ProfileService.acceptFriendRequest(senderId, senderName, senderImage);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$senderName is now your friend!")));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await ProfileService.removeFriend(senderId); 
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request from $senderName declined.")));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFindPlayersTab() {
     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(spacing: 8.0, children: [
                _buildFilterChip(label: 'Online Only', isSelected: _showOnlineOnly, onTap: () => setState(() => _showOnlineOnly = !_showOnlineOnly)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
    .collection('users')
    // 💡 OPTIMIZE: Fetch a manageable list (e.g., sort by last active to prioritize recent users)
    .orderBy('updatedAt', descending: true)
    .limit(50) // Limit to a max of 50 users
    .snapshots(),
              builder: (context, snapshot) {
                // 🛑 CHANGE: Show skeleton while waiting
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonList();
                }

                var players = snapshot.data!.docs
                    .map(_mapDocumentToPlayer)
                    .where((p) => p.id != FirebaseAuth.instance.currentUser?.uid) 
                    .toList();

                if (_searchQuery.isNotEmpty) {
                     players = players.where((p) => p.displayName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                if (_showOnlineOnly) {
                    players = players.where((p) => p.isOnline).toList();
                }
                
                if (players.isEmpty) return const Center(child: Text("No players found.", style: TextStyle(color: Colors.white54)));

                return ListView.builder(itemCount: players.length, itemBuilder: (context, index) => _buildPlayerTile(players[index]));
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController( 
      length: 3, 
      child: Scaffold(
        backgroundColor: const Color(0xff0E141B),
        appBar: AppBar(
          backgroundColor: const Color(0xff0E141B),
          elevation: 0,
          toolbarHeight: 50,
          bottom: const TabBar(
            indicatorColor: Colors.deepPurpleAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "Find Players"),
              Tab(text: "My Friends"),
              Tab(text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFindPlayersTab(),
            _buildFriendsList(),
            _buildRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(PlayerDisplay player) {
    final bool hasProfileImage = player.profileImage.isNotEmpty;
    final String initials = player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ReadOnlyProfilePage(userId: player.id)));
        },
        leading: CircleAvatar(
          backgroundColor: hasProfileImage ? Colors.transparent : Colors.grey.shade700,
          radius: 24,
          child: hasProfileImage ? ClipOval(child: Image.network(player.profileImage, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18))),))
              : Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18))),
        ),
        title: Text(player.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("${player.preferredGenres.take(2).join(", ")}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      ),
    );
 
  }
}