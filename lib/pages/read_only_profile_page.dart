// lib/pages/read_only_profile_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/avatar_urls.dart';
import '../services/profile_service.dart'; 
import '../models/board_game.dart'; 
import 'profile_page.dart'; // Import models (FavoriteGame, UserProfile)

// --- Reused Data Models (Required for this file's logic) ---
// Note: These models must mirror the ones in profile_page.dart

class FavoriteGame {
  final String id;
  final String name;
  final String image;
  FavoriteGame({required this.id, required this.name, required this.image});
  factory FavoriteGame.fromMap(Map<String, dynamic> map) {
    return FavoriteGame(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? 'Unknown',
      image: map['image'] as String? ?? '',
    );
  }
}

class UserProfile {
  String displayName;
  String profileImage;
  String aboutMe;
  List<String> preferredGenres;
  String topGenre;
  int ownedGamesCount;
  List<FavoriteGame> favoriteGames;

  UserProfile({
    required this.displayName,
    required this.profileImage,
    required this.aboutMe,
    required this.preferredGenres,
    required this.topGenre,
    required this.ownedGamesCount,
    required this.favoriteGames,
  });

  UserProfile copyWith({
    String? displayName,
    String? profileImage,
    String? aboutMe,
    List<String>? preferredGenres,
    String? topGenre,
    int? ownedGamesCount,
    List<FavoriteGame>? favoriteGames,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      profileImage: profileImage ?? this.profileImage,
      aboutMe: aboutMe ?? this.aboutMe,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      topGenre: topGenre ?? this.topGenre,
      ownedGamesCount: ownedGamesCount ?? this.ownedGamesCount,
      favoriteGames: favoriteGames ?? this.favoriteGames,
    );
  }
}


/// --- Read-Only Profile Page Widget (Phase 2, Item 10) ---

class ReadOnlyProfilePage extends StatefulWidget {
  final String userId; 

  const ReadOnlyProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ReadOnlyProfilePage> createState() => _ReadOnlyProfilePageState();
}

class _ReadOnlyProfilePageState extends State<ReadOnlyProfilePage> {
  late UserProfile _profile;
  
  @override
  void initState() {
    super.initState();
    _profile = UserProfile(
      displayName: 'Loading...', 
      profileImage: AVATAR_URLS.first,
      aboutMe: "No bio available.",
      preferredGenres: [], 
      topGenre: 'N/A', 
      ownedGamesCount: 0, 
      favoriteGames: [],
    );
  }

  void _updateProfileState(Map<String, dynamic> data) {
    if (data.isNotEmpty && mounted) {
      final List<String> genres = (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final int gamesCount = (data['ownedGamesCount'] as num?)?.toInt() ?? 0;
      
      List<FavoriteGame> fetchedFavorites = [];
      if (data['favoriteGames'] != null) {
        fetchedFavorites = (data['favoriteGames'] as List).map((item) {
          return FavoriteGame.fromMap(item as Map<String, dynamic>);
        }).toList();
      }
      
      String savedImageUrl = data['profileImage'] as String? ?? AVATAR_URLS.first; 
      
      setState(() {
        _profile = _profile.copyWith(
          displayName: data['displayName'] as String? ?? 'Unknown User',
          profileImage: savedImageUrl, 
          aboutMe: data['aboutMe'] as String? ?? _profile.aboutMe,
          preferredGenres: genres,
          topGenre: data['topGenre'] as String? ?? _profile.topGenre,
          ownedGamesCount: gamesCount,
          favoriteGames: fetchedFavorites,
        );
      });
    }
  }

  // --- UI Builder Methods (Read-Only Versions) ---

  Widget _buildHeaderCard(UserProfile currentProfile) {
    final String imageUrlToDisplay = currentProfile.profileImage.isNotEmpty 
        ? currentProfile.profileImage 
        : AVATAR_URLS.first; 
        
    final String displayId = widget.userId.length > 8 
        ? '${widget.userId.substring(0, 8)}...' 
        : widget.userId;

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Center(
          child: Column(
            children: [
              // Avatar Display
              Container(
                width: 136, height: 136,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFFF97316)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 64,
                  backgroundImage: NetworkImage(imageUrlToDisplay), 
                ),
              ),
              const SizedBox(height: 16),
              // Display Name
              Text(currentProfile.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 4),
              Text(
                'User ID: $displayId',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutMeCard(UserProfile currentProfile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('About Me', const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          Text(currentProfile.aboutMe, style: const TextStyle(fontSize: 16, color: Color(0xFF374151), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGenresCard(UserProfile currentProfile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Preferred Genres', const Color(0xFFF97316)),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), 
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFFF97316)])
            ), 
            child: Text('⭐ ${currentProfile.topGenre}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: currentProfile.preferredGenres.map((genre) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF93C5FD))),
              child: Text(genre, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 14)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(UserProfile currentProfile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Collection Overview', const Color(0xFFFBBF24)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFEEADF)])),
                child: Text('${currentProfile.ownedGamesCount} Games', style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: currentProfile.favoriteGames.isEmpty
                ? Center(child: Text("${currentProfile.displayName} has no top favorites selected.", style: const TextStyle(color: Colors.grey)))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var game in currentProfile.favoriteGames)
                          Padding(padding: const EdgeInsets.only(right: 12), child: GameCard(game: game)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Basic Helpers (Unchanged) ---
  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.0), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(24.0),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(children: [Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(right: 12.0)), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))]);
  }
  
  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    // 💡 Fetch profile data by the ID passed to the widget
    return StreamBuilder<Map<String, dynamic>>( 
      stream: ProfileService.getProfileStreamById(widget.userId),
      builder: (context, snapshot) {
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateProfileState(snapshot.data!);
          });
        }

        final currentProfile = _profile;

        if (snapshot.connectionState == ConnectionState.waiting && currentProfile.displayName == 'Loading...') {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (currentProfile.displayName == 'Unknown User' || snapshot.data == null || snapshot.data!.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profile Not Found'), backgroundColor: const Color(0xFFDC2626)),
              body: const Center(child: Text("Profile data could not be loaded or user is not discoverable.", style: TextStyle(color: Colors.grey))),
            );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(currentProfile.displayName, style: const TextStyle(color: Colors.black87)), 
            backgroundColor: Colors.white, 
            elevation: 1,
            foregroundColor: const Color(0xFF1F2937),
          ),
          body: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED), Color(0xFFFFFBEB)])),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(currentProfile),
                      const SizedBox(height: 16),
                      _buildAboutMeCard(currentProfile),
                      const SizedBox(height: 16),
                      _buildGenresCard(currentProfile),
                      const SizedBox(height: 16),
                      _buildCollectionCard(currentProfile),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- GameCard (Copied from ProfilePage) ---
class GameCard extends StatelessWidget {
  final FavoriteGame game;
  const GameCard({Key? key, required this.game}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 128, child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Stack(children: [Image.network(game.image, width: 128, height: 160, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], width: 128, height: 160, child: const Center(child: Icon(Icons.broken_image)))), Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.2), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)), alignment: Alignment.bottomLeft, padding: const EdgeInsets.all(8.0), child: Text(game.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))))])));
  }
}