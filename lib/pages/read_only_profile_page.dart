// lib/pages/read_only_profile_page.dart (FIXED: Direct Stream Consumption)
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/avatar_urls.dart';
import '../services/profile_service.dart'; 
import 'profile_page.dart'; // Import for UserProfile model

class ReadOnlyProfilePage extends StatefulWidget {
  final String userId; 
  const ReadOnlyProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ReadOnlyProfilePage> createState() => _ReadOnlyProfilePageState();
}

class _ReadOnlyProfilePageState extends State<ReadOnlyProfilePage> {
  // 💡 HELPER: Convert Firestore Map to UserProfile
  UserProfile _mapDataToProfile(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return UserProfile(
        displayName: 'Unknown User',
        profileImage: AVATAR_URLS.first,
        aboutMe: "No bio available.",
        preferredGenres: [],
        topGenre: 'N/A',
        ownedGamesCount: 0,
        favoriteGames: [],
      );
    }

    final List<String> genres = (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final int gamesCount = (data['ownedGamesCount'] as num?)?.toInt() ?? 0;
    String savedImageUrl = data['profileImage'] as String? ?? AVATAR_URLS.first;

    List<FavoriteGame> fetchedFavorites = [];
    if (data['favoriteGames'] != null) {
      fetchedFavorites = (data['favoriteGames'] as List).map((item) {
        return FavoriteGame.fromMap(item as Map<String, dynamic>);
      }).toList();
    }

    return UserProfile(
      displayName: data['displayName'] as String? ?? 'Unknown User',
      profileImage: savedImageUrl, 
      aboutMe: data['aboutMe'] as String? ?? 'No bio available.',
      preferredGenres: genres,
      topGenre: data['topGenre'] as String? ?? 'N/A',
      ownedGamesCount: gamesCount,
      favoriteGames: fetchedFavorites,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>( 
      stream: ProfileService.getProfileStreamById(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xff0E141B),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 💡 DATA MAPPING: Done directly in build, no setState side effects
        final UserProfile profile = _mapDataToProfile(snapshot.data);

        return Scaffold(
          backgroundColor: const Color(0xff0E141B),
          appBar: AppBar(
            title: Text(profile.displayName), 
            backgroundColor: const Color(0xFF171A21),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(radius: 60, backgroundImage: NetworkImage(profile.profileImage)),
                const SizedBox(height: 16),
                Text(profile.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                // Show partial ID for verification
                Text("User ID: ${widget.userId.substring(0, widget.userId.length > 6 ? 6 : widget.userId.length)}...", style: const TextStyle(color: Colors.grey)),
                
                const SizedBox(height: 24),
                
                // FRIEND ACTION BUTTON
                StreamBuilder<bool>(
                  stream: ProfileService.isFriend(widget.userId),
                  builder: (context, friendSnapshot) {
                    final isFriend = friendSnapshot.data ?? false;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isFriend) {
                            await ProfileService.removeFriend(widget.userId);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend removed.")));
                          } else {
                            await ProfileService.addFriend(widget.userId, profile.displayName, profile.profileImage);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend added!"), backgroundColor: Colors.green));
                          }
                        },
                        icon: Icon(isFriend ? Icons.person_remove : Icons.person_add, color: Colors.white),
                        label: Text(isFriend ? "Remove Friend" : "Add Friend", style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFriend ? Colors.redAccent : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 24),
                
                // Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF171A21), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn("Games", "${profile.ownedGamesCount}"),
                      _buildStatColumn("Top Genre", profile.topGenre),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                // About Me
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF171A21), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("About Me", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(profile.aboutMe, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                
                 if (profile.favoriteGames.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: Text("Top Favorites", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.favoriteGames.length,
                        itemBuilder: (context, index) {
                          final game = profile.favoriteGames[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 90,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(game.image, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                 ]
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}