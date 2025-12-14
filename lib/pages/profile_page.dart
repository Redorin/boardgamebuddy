// lib/pages/profile_page.dart (FINAL, UPDATED FOR USERNAME SYNC & EDITABLE FAVORITES)
import 'package:flutter/material.dart';
import '../utils/avatar_urls.dart'; // Retained for AVATAR_URLS constant
import '../services/profile_service.dart';
import '../services/game_service.dart';
import '../models/board_game.dart';

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

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'image': image};
  }

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
  String profileImage; // Stores the selected avatar URL
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

/// --- Profile Page Widget ---

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  // 💡 ADDED: Function to send the display name up to the HomePage AppBar
  final Function(String) onDisplayNameUpdate;

  const ProfilePage({
    super.key,
    required this.onLogout,
    required this.onDisplayNameUpdate, // 💡 REQUIRED
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late UserProfile _profile;
  late UserProfile _editedProfile;

  // Controllers
  late TextEditingController _displayNameController;
  late TextEditingController _aboutMeController;
  late TextEditingController _topGenreController;
  late TextEditingController _ownedGamesCountController;
  //late TextEditingController _newGenreController;

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
    //_newGenreController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutMeController.dispose();
    _topGenreController.dispose();
    _ownedGamesCountController.dispose();
    //_newGenreController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void _handleEdit() {
    setState(() {
      _editedProfile = _profile.copyWith(
        preferredGenres: List.from(_profile.preferredGenres),
        favoriteGames: List.from(_profile.favoriteGames),
        profileImage:
            _profile.profileImage, // Ensure the current saved image URL is used
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
      // Use the potentially new URL from _editedProfile state
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
      profileImage:
          newProfile.profileImage, // Passing the selected URL for saving
      favoriteGames: favoriteGamesMapList,
    );

    // 💡 SYNCHRONIZE HOMEPAGE AFTER SAVE
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

  /// New helper to remove a favorite game while editing (immediate UI feedback)
  void _removeFavorite(String favoriteId) {
    setState(() {
      _editedProfile = _editedProfile.copyWith(
        favoriteGames: _editedProfile.favoriteGames
            .where((g) => g.id != favoriteId)
            .toList(),
      );
    });
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

      // 💡 CALL CALLBACK ON LOAD: Pass the name up to HomePage for the initial load/stream update
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
            ownedGamesCount: realGameCount, // Set cached count
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

  void _showManageFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageFavoritesDialog(
        currentFavorites: _editedProfile.favoriteGames,
        onSelectionChanged: (selected) {
          setState(() {
            _editedProfile = _editedProfile.copyWith(favoriteGames: selected);
          });
        },
      ),
    );
  }

  void _showAvatarSelectionDialog() async {
    if (!_isEditing) return; // Only allow avatar changes in edit mode

    final String? resultUrl = await showDialog<String>(
      context: context,
      builder: (context) => const AvatarSelectionDialog(),
    );

    if (resultUrl != null) {
      setState(() {
        // Update the edited profile state with the new URL
        _editedProfile = _editedProfile.copyWith(profileImage: resultUrl);
      });
    }
  }

  void _showGenreSelectionDialog() async {
    if (!_isEditing) return;

    final List<String>? resultGenres = await showDialog<List<String>>(
      context: context,
      builder: (context) => GenreSelectionDialog(
        currentGenres: _editedProfile.preferredGenres,
        allGenres: MASTER_GENRE_LIST,
      ),
    );

    if (resultGenres != null) {
      setState(() {
        _editedProfile = _editedProfile.copyWith(preferredGenres: resultGenres);
      });
    }
  }

  // --- UI Builder Methods ---

  Widget _buildHeaderCard(UserProfile currentProfile) {
    final String imageUrlToDisplay = currentProfile.profileImage.isNotEmpty
        ? currentProfile.profileImage
        : AVATAR_URLS.first;

    return _buildCard(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEditing)
                  _buildButton(
                    onPressed: _handleEdit,
                    text: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    backgroundColor: const Color(0xFF2563EB),
                  )
                else ...[
                  _buildButton(
                    onPressed: _handleSave,
                    text: 'Save',
                    icon: Icons.save,
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    onPressed: _handleCancel,
                    text: 'Cancel',
                    icon: Icons.close,
                    backgroundColor: Colors.transparent,
                    textColor: const Color(0xFF6B7280),
                    borderColor: const Color(0xFFD1D5DB),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing
                        ? _showAvatarSelectionDialog
                        : null, // Opens selection dialog
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFFF97316)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent.shade100,
                            radius: 64,
                            backgroundImage: NetworkImage(imageUrlToDisplay),
                            child: null,
                          ),
                        ),
                        if (_isEditing)
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: const Icon(
                              Icons.palette,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing
                      ? SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _displayNameController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          currentProfile.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
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
          _isEditing
              ? TextField(
                  controller: _aboutMeController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tell us about yourself...',
                    border: const OutlineInputBorder(),
                    fillColor: Colors.grey[50],
                    filled: true,
                  ),
                  style: const TextStyle(color: Color(0xFF374151)),
                )
              : Text(
                  currentProfile.aboutMe,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
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

          // --- REMOVED: Top Genre Container (Gradient Pill / TextField) ---
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ...currentProfile.preferredGenres.map(
                (genre) => Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: _isEditing ? 4 : 12,
                    top: 6,
                    bottom: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        genre,
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 14,
                        ),
                      ),
                      if (_isEditing)
                        InkWell(
                          onTap: () => _removeGenre(genre),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0, right: 4.0),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isEditing)
                _buildButton(
                  onPressed: _showGenreSelectionDialog,
                  text: 'Select Genres',
                  icon: Icons.list_alt,
                  backgroundColor: const Color(0xFF14B8A6), // Teal color
                  textColor: Colors.white,
                ),
            ],
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
              _buildSectionHeader('My Collection', const Color(0xFFFBBF24)),
              if (_isEditing)
                _buildButton(
                  onPressed: _showManageFavoritesDialog,
                  icon: Icons.star,
                  text: 'Manage Top 5',
                  backgroundColor: const Color(0xFFFDE047),
                  textColor: Colors.black,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFEEADF)],
                    ),
                  ),
                  child: Text(
                    '${currentProfile.ownedGamesCount} Games',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: currentProfile.favoriteGames.isEmpty
                ? Center(
                    child: _isEditing
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "No favorites selected",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              _buildButton(
                                onPressed: _showManageFavoritesDialog,
                                icon: Icons.add,
                                text: 'Select Top 5',
                                backgroundColor: const Color(0xFFFDE047),
                                textColor: Colors.black,
                              ),
                            ],
                          )
                        : const Text(
                            "No favorites selected",
                            style: TextStyle(color: Colors.grey),
                          ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var game in currentProfile.favoriteGames)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GameCard(game: game),
                                if (_isEditing) // Show small remove button in edit mode
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Operate on editedProfile to keep changes local until save
                                        _removeFavorite(game.id);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              elevation: 0,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // --- Basic Helpers (Unchanged) ---
  Widget _buildButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required Color backgroundColor,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16.0),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: backgroundColor,
        minimumSize: const Size(64, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          margin: const EdgeInsets.only(right: 12.0),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // --- Main Build Method ---
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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E141B),
            elevation: 0,
            title: Text(
              currentProfile.displayName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF6FF),
                  Color(0xFFFFF7ED),
                  Color(0xFFFFFBEB),
                ],
              ),
            ),
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
                      const SizedBox(height: 16),
                      _buildLogoutButton(),
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

// --- Manage Favorites Dialog (Unchanged) ---
class ManageFavoritesDialog extends StatefulWidget {
  final List<FavoriteGame> currentFavorites;
  final Function(List<FavoriteGame>) onSelectionChanged;
  const ManageFavoritesDialog({
    super.key,
    required this.currentFavorites,
    required this.onSelectionChanged,
  });
  @override
  State<ManageFavoritesDialog> createState() => _ManageFavoritesDialogState();
}

class _ManageFavoritesDialogState extends State<ManageFavoritesDialog> {
  Set<String> _selectedIds = {};
  @override
  void initState() {
    super.initState();
    _selectedIds = widget.currentFavorites.map((g) => g.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BoardGame>>(
      stream: GameService.getUserCollectionGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final myGames = snapshot.data ?? [];

        return AlertDialog(
          title: const Text("Select Top 5 Games"),
          content: SizedBox(
            width: double.maxFinite,
            child: myGames.isEmpty
                ? const Text("You have no games in your collection to select.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: myGames.length,
                    itemBuilder: (context, index) {
                      final game = myGames[index];
                      final isSelected = _selectedIds.contains(game.id);
                      return CheckboxListTile(
                        title: Text(game.name),
                        subtitle: Text(game.category),
                        value: isSelected,
                        activeColor: Colors.deepPurpleAccent,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              if (_selectedIds.length < 5) {
                                _selectedIds.add(game.id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Max 5 games allowed"),
                                    duration: Duration(milliseconds: 500),
                                  ),
                                );
                              }
                            } else {
                              _selectedIds.remove(game.id);
                            }
                          });
                          // Auto-save selection
                          final List<FavoriteGame> selectedFavorites = myGames
                              .where((game) => _selectedIds.contains(game.id))
                              .map(
                                (game) => FavoriteGame(
                                  id: game.id,
                                  name: game.name,
                                  image: game.thumbnailUrl,
                                ),
                              )
                              .toList();
                          widget.onSelectionChanged(selectedFavorites);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final List<FavoriteGame> selectedFavorites = myGames
                    .where((game) => _selectedIds.contains(game.id))
                    .map(
                      (game) => FavoriteGame(
                        id: game.id,
                        name: game.name,
                        image: game.thumbnailUrl,
                      ),
                    )
                    .toList();
                Navigator.pop(context, selectedFavorites);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
              ),
              child: const Text(
                "Save Selection",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- GameCard (Unchanged) ---
class GameCard extends StatelessWidget {
  final FavoriteGame game;
  const GameCard({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            Image.network(
              game.image,
              width: 128,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                width: 128,
                height: 160,
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  game.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Avatar Selection Dialog (Unchanged) ---
class AvatarSelectionDialog extends StatelessWidget {
  const AvatarSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Your Avatar"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: AVATAR_URLS.length,
          itemBuilder: (context, index) {
            final url = AVATAR_URLS[index];
            return GestureDetector(
              onTap: () =>
                  Navigator.pop(context, url), // Return the selected URL
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(url),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, null), // Return null if cancelled
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}

class GenreSelectionDialog extends StatefulWidget {
  final List<String> currentGenres;
  final List<String> allGenres;

  const GenreSelectionDialog({
    super.key,
    required this.currentGenres,
    required this.allGenres,
  });

  @override
  State<GenreSelectionDialog> createState() => _GenreSelectionDialogState();
}

class _GenreSelectionDialogState extends State<GenreSelectionDialog> {
  late List<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.currentGenres);
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  Widget _buildGenreChip(String genre) {
    final isSelected = _selectedGenres.contains(genre);
    return FilterChip(
      label: Text(genre),
      selected: isSelected,
      onSelected: (bool selected) {
        _toggleGenre(genre);
      },
      selectedColor: const Color(0xFF6366F1), // Primary Indigo color
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF374151),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFFEFF6FF), // Light background
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Preferred Genres"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.allGenres.map(_buildGenreChip).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                "${_selectedGenres.length} selected",
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancelled
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, _selectedGenres), // Return list
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
          ),
          child: const Text("Save", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
