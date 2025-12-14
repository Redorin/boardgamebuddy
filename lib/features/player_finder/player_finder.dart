// lib/features/player_finder/player_finder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart'; 
import '../../core/services/profile_service.dart';
import '../profile/read_only_profile_page.dart';
import '../../core/services/game_session_service.dart'; 
import '../../core/models/game_session_invitation.dart'; 
import 'ui/invite_to_game_dialog.dart'; 

// --- Data Models (Keep these classes in your file) ---
class PlayerDisplay {
  final String id;
  final String displayName;
  final String profileImage;
  final List<String> preferredGenres;
  final bool isOnline;
  final int gamesOwned;
  final DateTime lastActiveTimestamp;

  PlayerDisplay({
    required this.id,
    required this.displayName,
    required this.profileImage,
    required this.preferredGenres,
    this.isOnline = false,
    this.gamesOwned = 0,
    required this.lastActiveTimestamp,
  });
}

enum SortOption { active, games }

class PlayerFinderPage extends StatefulWidget {
  const PlayerFinderPage({super.key});

  @override
  State<PlayerFinderPage> createState() => _PlayerFinderPageState();
}

class _PlayerFinderPageState extends State<PlayerFinderPage> {
  String _searchQuery = '';
  bool _showOnlineOnly = false;

  final TextEditingController _searchController = TextEditingController();

  final GameSessionService _gameSessionService = GameSessionService(); 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PlayerDisplay _mapDocumentToPlayer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final displayName = data['displayName'] as String? ?? 'Unknown';
    final profileImage = data['profileImage'] as String? ?? '';
    final genres =
        (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    final gamesCount = (data['ownedGamesCount'] as num?)?.toInt() ?? 0;
    final lastActive =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    final isOnline = DateTime.now().difference(lastActive).inMinutes < 15;

    return PlayerDisplay(
      id: doc.id,
      displayName: displayName,
      profileImage: profileImage,
      preferredGenres: genres,
      isOnline: isOnline,
      gamesOwned: gamesCount,
      lastActiveTimestamp: lastActive,
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.deepPurple.shade700,
      radius: 24,
      child: const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  Widget _buildSkeletonTile() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF171A21),
      highlightColor: const Color(0xFF2A3F5F),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const ListTile(
          leading: CircleAvatar(radius: 24, backgroundColor: Colors.black),
          title: Text(
            "Loading Player Name...",
            style: TextStyle(color: Colors.black),
          ),
          subtitle: Text(
            "Loading genres...",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonTile(),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFFC0C0C0),
        ),
      ),
      avatar: isSelected
          ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
          : null,
      onPressed: onTap,
      backgroundColor: isSelected
          ? const Color(0xFF673AB7)
          : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF673AB7)
              : Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ProfileService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonList();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading friends: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return const Center(
            child: Text(
              "You haven't added any friends yet.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final friend = friends[index];
            final friendId = friend['id'] as String? ?? '0';
            final friendName = friend['displayName'] as String? ?? 'Unknown';
            final friendImage = friend['profileImage'] as String? ?? '';
            final isUrlValid = friendImage.isNotEmpty;

            return Card(
              color: const Color(0xFF171A21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: isUrlValid
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(friendImage),
                        radius: 24,
                        onBackgroundImageError: (exception, stackTrace) => {},
                      )
                    : const CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        radius: 24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                title: Text(
                  friendName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.gamepad2,
                          color: Colors.deepPurpleAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => InviteToGameDialog(
                            inviteeId: friendId,
                            inviteeName: friendName,
                            inviteeImage: friendImage,
                          ),
                        );
                      },
                      tooltip: 'Invite to Game',
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReadOnlyProfilePage(userId: friendId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ProfileService.getIncomingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonList();
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Text(
              "No incoming friend requests.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final request = requests[index];
            final senderId = request['senderId'] as String? ?? '';
            final senderName =
                request['senderName'] as String? ?? 'Unknown User';
            final senderImage = request['senderImage'] as String? ?? '';
            final isUrlValid = senderImage.isNotEmpty;

            return Card(
              color: const Color(0xFF171A21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: isUrlValid
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(senderImage),
                        radius: 24,
                        onBackgroundImageError: (exception, stackTrace) =>
                            {},
                      )
                    : _buildDefaultAvatar(),
                title: Text(
                  senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Sent you a request",
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await ProfileService.acceptFriendRequest(
                          senderId,
                          senderName,
                          senderImage,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("$senderName is now your friend!"),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await ProfileService.removeFriend(senderId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Request from $senderName declined.",
                              ),
                            ),
                          );
                        }
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

  // NEW: Method to build the list of incoming game invitations
  Widget _buildGameInvitationsTab() {
    return StreamBuilder<List<GameSessionInvitation>>(
      stream: _gameSessionService.getIncomingInvitationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonList();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading invitations: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final invitations = snapshot.data ?? [];
        if (invitations.isEmpty) {
          return const Center(
            child: Text(
              "No pending game invitations.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: invitations.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final invite = invitations[index];
            final isUrlValid = invite.inviterImage.isNotEmpty;
            final DateFormat formatter = DateFormat('EEE, MMM d, h:mm a');
            final dateTimeString = formatter.format(invite.sessionDate);

            return Card(
              color: const Color(0xFF171A21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: isUrlValid
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(invite.inviterImage),
                        radius: 24,
                        onBackgroundImageError: (exception, stackTrace) =>
                            {},
                      )
                    : _buildDefaultAvatar(),
                title: Text(
                  'Game Invitation from ${invite.inviterName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game: ${invite.gameName}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'When: $dateTimeString',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Where: ${invite.sessionLocation}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Accept Button
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _gameSessionService.respondToInvitation(
                          invite.id,
                          InvitationStatus.accepted,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Accepted invitation for ${invite.gameName}!"),
                            ),
                          );
                        }
                      },
                      tooltip: 'Accept',
                    ),
                    // Reject Button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _gameSessionService.respondToInvitation(
                          invite.id,
                          InvitationStatus.rejected,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Declined invitation for ${invite.gameName}."),
                              ),
                          );
                        }
                      },
                      tooltip: 'Reject',
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
              hintText: 'Search players or genres...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8.0,
              children: [
                _buildFilterChip(
                  label: 'Online Only',
                  isSelected: _showOnlineOnly,
                  onTap: () =>
                      setState(() => _showOnlineOnly = !_showOnlineOnly),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonList();
                }

                var players = snapshot.data!.docs
                    .map(_mapDocumentToPlayer)
                    .where(
                      (p) => p.id != FirebaseAuth.instance.currentUser?.uid,
                    )
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  players = players
                      .where(
                        (p) => p.displayName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
                }
                if (_showOnlineOnly) {
                  players = players.where((p) => p.isOnline).toList();
                }

                if (players.isEmpty) {
                  return const Center(
                    child: Text(
                      "No players found.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) =>
                      _buildPlayerTile(players[index]),
                );
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
      length: 4, 
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
              Tab(text: "Game Invites"), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFindPlayersTab(),
            _buildFriendsList(),
            _buildRequestsList(),
            _buildGameInvitationsTab(), 
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(PlayerDisplay player) {
    final bool hasProfileImage = player.profileImage.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadOnlyProfilePage(userId: player.id),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade700,
          radius: 24,
          child: hasProfileImage
              ? ClipOval(
                  child: Image.network(
                    player.profileImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
        ),
        title: Text(
          player.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          player.preferredGenres.take(2).join(", "),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      ),
    );
  }
}