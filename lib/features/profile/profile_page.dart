// lib/features/profile/profile_page.dart (FINAL, UPDATED FOR USERNAME SYNC & FAVORITES FIX)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/utils/avatar_urls.dart'; // Retained for AVATAR_URLS constant
import '../../shared/config/app_theme.dart';
import '../../core/services/profile_service.dart';
// [FIXES: ADDED IMPORTS]
import '../../core/services/game_service.dart';
import '../../core/models/board_game.dart';

// --- Data Models (Ensure these match your file's structure) ---

const List<String> MASTER_GENRE_LIST = [
  'Strategy',
  'Engine Building',
  'Area Control',
  'Abstract Strategy',
  'Worker Placement',
  'Deck Building',
  'Tile Placement',
  'Economics',
  'Tech Tree',
  'Cooperative',
  'RPG',
  'Campaign',
  'Thematic',
  'Horror',
  'App Driven',
  'Card Game',
  'Survival',
  'Asymmetric',
  'Push Your Luck',
  'Dice Rolling',
  'Card Drafting',
  'Party Game',
  'Drawing',
  'Word',
  'Deduction',
  'Abstract',
  '2-Player',
  'Family',
  'Miniatures',
];

class FavoriteGame {
  final String id;
  final String name;
  final String image;
  FavoriteGame({required this.id, required this.name, required this.image});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'image': image};
  factory FavoriteGame.fromMap(Map<String, dynamic> map) => FavoriteGame(
    id: map['id']?.toString() ?? '',
    name: map['name'] as String? ?? 'Unknown',
    image: map['image'] as String? ?? '',
  );
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

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  final Function(String) onDisplayNameUpdate;

  const ProfilePage({
    Key? key,
    required this.onLogout,
    required this.onDisplayNameUpdate,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late UserProfile _profile;
  late UserProfile _editedProfile;

  late TextEditingController _displayNameController;
  late TextEditingController _aboutMeController;
  late TextEditingController _topGenreController;
  late TextEditingController _ownedGamesCountController;

  static const String _defaultProfileImage = '';

  @override
  void initState() {
    super.initState();
    _profile = UserProfile(
      displayName: 'Loading...',
      profileImage: _defaultProfileImage,
      aboutMe: "Tell us about your board game passion!",
      preferredGenres: [],
      topGenre: 'Strategy',
      ownedGamesCount: 0,
      favoriteGames: [],
    );
    _editedProfile = _profile.copyWith();
    _displayNameController = TextEditingController(text: _profile.displayName);
    _aboutMeController = TextEditingController(text: _profile.aboutMe);
    _topGenreController = TextEditingController(text: _profile.topGenre);
    _ownedGamesCountController = TextEditingController(
      text: _profile.ownedGamesCount.toString(),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutMeController.dispose();
    _topGenreController.dispose();
    _ownedGamesCountController.dispose();
    super.dispose();
  }

  void _handleEdit() {
    setState(() {
      _editedProfile = _profile.copyWith(
        preferredGenres: List.from(_profile.preferredGenres),
        favoriteGames: List.from(_profile.favoriteGames),
        profileImage: _profile.profileImage,
      );
      _displayNameController.text = _editedProfile.displayName;
      _aboutMeController.text = _editedProfile.aboutMe;
      _topGenreController.text = _editedProfile.topGenre;
      _ownedGamesCountController.text = _editedProfile.ownedGamesCount
          .toString();
      _isEditing = true;
    });
  }

  void _handleSave() async {
    final newProfile = _editedProfile.copyWith(
      displayName: _displayNameController.text,
      aboutMe: _aboutMeController.text,
      topGenre: _topGenreController.text,
      ownedGamesCount: _profile.ownedGamesCount,
      preferredGenres: List.from(_editedProfile.preferredGenres),
      favoriteGames: List.from(_editedProfile.favoriteGames),
      profileImage: _editedProfile.profileImage,
    );

    final favoriteGamesMapList = newProfile.favoriteGames
        .map((g) => g.toMap())
        .toList();

    await ProfileService.saveProfileEdits(
      displayName: newProfile.displayName,
      aboutMe: newProfile.aboutMe,
      preferredGenres: newProfile.preferredGenres,
      topGenre: newProfile.topGenre,
      profileImage: newProfile.profileImage,
      favoriteGames: favoriteGamesMapList,
    );

    widget.onDisplayNameUpdate(newProfile.displayName);
    setState(() {
      _profile = newProfile;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile updated!"),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _handleCancel() {
    setState(() {
      _editedProfile = _profile.copyWith();
      _isEditing = false;
    });
  }

  void _removeGenre(String genreToRemove) {
    setState(() {
      _editedProfile = _editedProfile.copyWith(
        preferredGenres: _editedProfile.preferredGenres
            .where((g) => g != genreToRemove)
            .toList(),
      );
    });
  }

  // [FIXED] Replaced manual input dialog with collection-based selection dialog
  void _showAddGameDialog() {
    showDialog(
      context: context,
      builder: (context) => CollectionGameSelectionDialog(
        currentFavorites: _editedProfile.favoriteGames,
        onFavoritesSelected: (newFavorites) {
          setState(() {
            _editedProfile = _editedProfile.copyWith(
              favoriteGames: newFavorites,
            );
          });
          Navigator.pop(context); // Pop the dialog after selection
        },
      ),
    );
  }

  void _updateProfileState(Map<String, dynamic> data) async {
    if (data.isNotEmpty) {
      final List<String> genres =
          (data['preferredGenres'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final int realGameCount = (data['ownedGamesCount'] as num?)?.toInt() ?? 0;
      List<FavoriteGame> fetchedFavorites = [];
      if (data['favoriteGames'] != null) {
        fetchedFavorites = (data['favoriteGames'] as List).map((item) {
          return FavoriteGame.fromMap(item as Map<String, dynamic>);
        }).toList();
      }
      String savedImageUrl =
          data['profileImage'] as String? ?? AVATAR_URLS.first;
      String newDisplayName =
          data['displayName'] as String? ?? _profile.displayName;

      if (newDisplayName != _profile.displayName) {
        widget.onDisplayNameUpdate(newDisplayName);
      }

      if (!_isEditing) {
        setState(() {
          _profile = _profile.copyWith(
            displayName: newDisplayName,
            profileImage: savedImageUrl,
            aboutMe: data['aboutMe'] as String? ?? _profile.aboutMe,
            preferredGenres: genres,
            topGenre: data['topGenre'] as String? ?? _profile.topGenre,
            ownedGamesCount: realGameCount,
            favoriteGames: fetchedFavorites,
          );
          _displayNameController.text = _profile.displayName;
          _aboutMeController.text = _profile.aboutMe;
          _topGenreController.text = _profile.topGenre;
          _ownedGamesCountController.text = realGameCount.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService.getUserProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateProfileState(snapshot.data!);
          });
        }

        final currentProfile = _isEditing ? _editedProfile : _profile;

        if (snapshot.connectionState == ConnectionState.waiting &&
            currentProfile.displayName == 'Loading...') {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top action bar with Edit and Logout
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!_isEditing)
                        Row(
                          children: [
                            IconButton(
                              onPressed: _handleEdit,
                              icon: const Icon(LucideIcons.edit),
                              color: AppColors.primary,
                              tooltip: 'Edit Profile',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: widget.onLogout,
                              icon: const Icon(LucideIcons.logOut),
                              color: AppColors.error,
                              tooltip: 'Logout',
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              onPressed: _handleSave,
                              icon: const Icon(LucideIcons.check),
                              color: AppColors.success,
                              tooltip: 'Save',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _handleCancel,
                              icon: const Icon(LucideIcons.x),
                              color: AppColors.error,
                              tooltip: 'Cancel',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Profile Header Card (Avatar + Name)
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _isEditing
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AvatarSelectionDialog(
                                    onAvatarSelected: (url) {
                                      setState(() {
                                        _editedProfile = _editedProfile
                                            .copyWith(profileImage: url);
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              }
                            : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.surface,
                              backgroundImage: NetworkImage(
                                currentProfile.profileImage.isEmpty
                                    ? AVATAR_URLS.first
                                    : currentProfile.profileImage,
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display Name
                      if (_isEditing)
                        TextField(
                          controller: _displayNameController,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Display Name',
                            hintStyle: TextStyle(color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          currentProfile.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                currentProfile.ownedGamesCount.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Games',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                currentProfile.preferredGenres.length
                                    .toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                'Genres',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // About Me Card
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Me',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        TextField(
                          controller: _aboutMeController,
                          style: TextStyle(color: AppColors.textPrimary),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Tell us about your board game passion!',
                            hintStyle: TextStyle(color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          currentProfile.aboutMe,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Genres Card
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Genres',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _editedProfile.preferredGenres
                                  .map(
                                    (genre) => GestureDetector(
                                      onTap: () => _removeGenre(genre),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              genre,
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              LucideIcons.x,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => GenreSelectionDialog(
                                    selectedGenres:
                                        _editedProfile.preferredGenres,
                                    onGenresSelected: (genres) {
                                      setState(() {
                                        _editedProfile = _editedProfile
                                            .copyWith(preferredGenres: genres);
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add Genre',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.plus,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: currentProfile.preferredGenres
                              .map(
                                (genre) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    genre,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Favorite Games Card
                // [FIXED CONDITION]: Show card if editing OR if there are games to display (non-editing view).
                if (_isEditing || currentProfile.favoriteGames.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppColors.darkBgSecondary,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Favorite Games',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_isEditing)
                              GestureDetector(
                                onTap: () => _showAddGameDialog(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.accent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Add Game',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        LucideIcons.plus,
                                        size: 14,
                                        color: AppColors.accent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if ((_isEditing
                                ? _editedProfile.favoriteGames
                                : currentProfile.favoriteGames)
                            .isEmpty)
                          Text(
                            'No favorite games selected yet',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount:
                                (_isEditing
                                        ? _editedProfile.favoriteGames
                                        : currentProfile.favoriteGames)
                                    .length,
                            itemBuilder: (context, index) {
                              final game = (_isEditing
                                  ? _editedProfile.favoriteGames
                                  : currentProfile.favoriteGames)[index];
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(game.image),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Text(
                                      game.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _editedProfile.favoriteGames
                                                .removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            LucideIcons.x,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Avatar Selection Dialog

class AvatarSelectionDialog extends StatelessWidget {
  final Function(String) onAvatarSelected;

  const AvatarSelectionDialog({Key? key, required this.onAvatarSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBgSecondary,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Avatar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AVATAR_URLS.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onAvatarSelected(AVATAR_URLS[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(AVATAR_URLS[index]),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Genre Selection Dialog
class GenreSelectionDialog extends StatefulWidget {
  final List<String> selectedGenres;
  final Function(List<String>) onGenresSelected;

  const GenreSelectionDialog({
    Key? key,
    required this.selectedGenres,
    required this.onGenresSelected,
  }) : super(key: key);

  @override
  State<GenreSelectionDialog> createState() => _GenreSelectionDialogState();
}

class _GenreSelectionDialogState extends State<GenreSelectionDialog> {
  late List<String> _tempGenres;

  @override
  void initState() {
    super.initState();
    _tempGenres = List.from(widget.selectedGenres);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBgSecondary,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Genres',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MASTER_GENRE_LIST.map((genre) {
                    final isSelected = _tempGenres.contains(genre);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _tempGenres.remove(genre);
                          } else {
                            _tempGenres.add(genre);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onGenresSelected(_tempGenres);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// [NEW WIDGET] Collection Game Selection Dialog
class CollectionGameSelectionDialog extends StatefulWidget {
  final List<FavoriteGame> currentFavorites;
  final Function(List<FavoriteGame>) onFavoritesSelected;

  const CollectionGameSelectionDialog({
    Key? key,
    required this.currentFavorites,
    required this.onFavoritesSelected,
  }) : super(key: key);

  @override
  State<CollectionGameSelectionDialog> createState() =>
      _CollectionGameSelectionDialogState();
}

class _CollectionGameSelectionDialogState
    extends State<CollectionGameSelectionDialog> {
  late List<FavoriteGame> _tempFavorites;

  @override
  void initState() {
    super.initState();
    // Initialize temporary list from current favorites for local mutation
    _tempFavorites = List.from(widget.currentFavorites);
  }

  void _toggleFavorite(BoardGame game) {
    setState(() {
      final index =
          _tempFavorites.indexWhere((fav) => fav.id == game.id);

      if (index != -1) {
        // Game is already a favorite, so remove it
        _tempFavorites.removeAt(index);
      } else {
        // Game is not a favorite, so add it
        _tempFavorites.add(
          FavoriteGame(
            id: game.id,
            name: game.name,
            image: game.thumbnailUrl, // Use BoardGame's thumbnailUrl as image
          ),
        );
      }
    });
  }

  bool _isGameSelected(String gameId) {
    return _tempFavorites.any((fav) => fav.id == gameId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBgSecondary,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Favorite Games',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<BoardGame>>(
                // Fetch the user's collection to populate the dialog
                stream: GameService.getUserCollectionGames(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading collection: ${snapshot.error}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  }
                  final games = snapshot.data ?? [];
                  if (games.isEmpty) {
                    return Center(
                      child: Text(
                        'Your collection is empty. Add games first!',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final isSelected = _isGameSelected(game.id);

                      return ListTile(
                        onTap: () => _toggleFavorite(game),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            game.thumbnailUrl.isEmpty
                                ? 'https://via.placeholder.com/60'
                                : game.thumbnailUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          game.name,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        trailing: Icon(
                          isSelected
                              ? LucideIcons.checkCircle
                              : LucideIcons.circle,
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Pass the new list of favorites back to the parent widget
                    widget.onFavoritesSelected(_tempFavorites);
                    // The parent widget will call Navigator.pop(context)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Save Favorites (${_tempFavorites.length})',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}