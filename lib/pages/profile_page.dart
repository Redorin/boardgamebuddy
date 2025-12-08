import 'package:flutter/material.dart';
//import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// NOTE: Make sure you have 'flutter_staggered_grid_view' in your pubspec.yaml

/// --- Data Models ---

class FavoriteGame {
  final int id;
  final String name;
  final String image;

  FavoriteGame({required this.id, required this.name, required this.image});
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

  // Simple copy method for state management
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

  const ProfilePage({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late UserProfile _profile;
  late UserProfile _editedProfile;

  // Controllers for text fields
  late TextEditingController _displayNameController;
  late TextEditingController _aboutMeController;
  late TextEditingController _topGenreController;
  late TextEditingController _ownedGamesCountController;
  late TextEditingController _newGenreController;

  @override
  void initState() {
    super.initState();
    // Initialize with mock data
    _profile = UserProfile(
      displayName: 'BoardGameMaster42',
      profileImage: 'https://images.unsplash.com/photo-1529995049601-ef63465a463f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXJzb24lMjBwcm9maWxlJTIwcG9ydHJhaXR8ZW58MXx8fHwxNzY1MTQ2MjE0fDA&ixlib=rb-4.1.0&q=80&w=1080',
      aboutMe: "Always up for a heavy Euro game, but will never say no to a quick round of Codenames. I love games that make you think strategically and offer tough decisions!",
      preferredGenres: ['Eurogame', 'Cooperative', 'Deck Builder', 'Legacy', 'Worker Placement'],
      topGenre: 'Strategy',
      ownedGamesCount: 145,
      favoriteGames: [
        FavoriteGame(id: 1, name: 'Wingspan', image: 'https://images.unsplash.com/photo-1677816156349-5fa568399cce?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHxzdHJhdGVneSUyMGJvYXJkJTIwZ2FtZXxlbnwxfHx8fDE3NjUwNjA4Njl8MA&ixlib=rb-4.1.0&q=80&w=1080'),
        FavoriteGame(id: 2, name: 'Pandemic', image: 'https://images.unsplash.com/photo-1648422125119-351b24ee8ad6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHxjb29wZXJhdGl2ZSUyMGJvYXJkJTIwZ2FtZXxlbnwxfHx8fDE3NjUxNTU4NjJ8MA&lib=rb-4.1.0&q=80&w=1080'),
        FavoriteGame(id: 3, name: 'Dominion', image: 'https://images.unsplash.com/photo-1728167049092-de4e98571c1b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHxjYXJkJTIwZ2FtZSUyMGRlY2t8ZW58MXx8fHwxNzY1MTU1ODYyfDA&lib=rb-4.1.0&q=80&w=1080'),
        FavoriteGame(id: 4, name: 'Azul', image: 'https://images.unsplash.com/photo-1653080583930-37db86ec6a1f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHx0YWJsZXRvcCUyMGdhbWUlMjBwaWVjZXN8ZW58MXx8fHwxNzY1MDkyMTU1fDA&lib=rb-4.1.0&q=80&w=1080'),
        FavoriteGame(id: 5, name: 'Ticket to Ride', image: 'https://images.unsplash.com/photo-1716817279190-a56b0cb05da1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib2FyZCUyMGdhbWUlMjBjb2xsZWN0aW9ufGVufDF8fHx8MTc2NTE1NTg2Mnww&lib=rb-4.1.0&q=80&w=1080'),
        FavoriteGame(id: 6, name: 'King of Tokyo', image: 'https://images.unsplash.com/photo-1596687909057-dfac2b25b891?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHxkaWNlJTIwZ2FtZSUyMGNvbG9yZnVsfGVufDF8fHx8MTc2NTA5MjE1Nnww&lib=rb-4.1.0&q=80&w=1080'),
        FavoriteGame(id: 7, name: 'Codenames', image: 'https://images.unsplash.com/photo-1725398927288-695dcd8db014?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHxwYXJ0eSUyMGdhbWUlMjBmdW58ZW58MXx8fHwxNzY1MTU1ODY1fDA&lib=rb-4.1.0&q=80&w=1080'),
      ],
    );
    _editedProfile = _profile.copyWith();

    _displayNameController = TextEditingController(text: _profile.displayName);
    _aboutMeController = TextEditingController(text: _profile.aboutMe);
    _topGenreController = TextEditingController(text: _profile.topGenre);
    _ownedGamesCountController = TextEditingController(text: _profile.ownedGamesCount.toString());
    _newGenreController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutMeController.dispose();
    _topGenreController.dispose();
    _ownedGamesCountController.dispose();
    _newGenreController.dispose();
    super.dispose();
  }

  void _handleEdit() {
    setState(() {
      _editedProfile = _profile.copyWith(
        preferredGenres: List.from(_profile.preferredGenres), // Deep copy list
      );
      _displayNameController.text = _editedProfile.displayName;
      _aboutMeController.text = _editedProfile.aboutMe;
      _topGenreController.text = _editedProfile.topGenre;
      _ownedGamesCountController.text = _editedProfile.ownedGamesCount.toString();
      _isEditing = true;
    });
  }

  void _handleSave() {
    setState(() {
      _profile = _editedProfile.copyWith(
        displayName: _displayNameController.text,
        aboutMe: _aboutMeController.text,
        topGenre: _topGenreController.text,
        ownedGamesCount: int.tryParse(_ownedGamesCountController.text) ?? _profile.ownedGamesCount,
        preferredGenres: List.from(_editedProfile.preferredGenres),
      );
      _isEditing = false;
    });
    // NOTE: In a real app, you would call a service method here:
    // GameService.updateUserProfile(_profile);
  }

  void _handleCancel() {
    setState(() {
      _editedProfile = _profile.copyWith(); // Revert changes
      _isEditing = false;
    });
  }

  void _addGenre(String genre) {
    String trimmedGenre = genre.trim();
    if (trimmedGenre.isNotEmpty && !_editedProfile.preferredGenres.contains(trimmedGenre)) {
      setState(() {
        _editedProfile = _editedProfile.copyWith(
          preferredGenres: [..._editedProfile.preferredGenres, trimmedGenre],
        );
      });
      _newGenreController.clear();
    }
  }

  void _removeGenre(String genreToRemove) {
    setState(() {
      // Create a new list without the genre to ensure state updates
      _editedProfile = _editedProfile.copyWith(
        preferredGenres: _editedProfile.preferredGenres.where((g) => g != genreToRemove).toList(),
      );
    });
  }

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
          side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
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
            color: Color(0xFF1F2937), // gray-900
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = _isEditing ? _editedProfile : _profile;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFFFF7ED), // orange-50
              Color(0xFFFFFBEB), // yellow-50
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
                  // --- Header/Profile Card ---
                  _buildCard(
                    child: Stack(
                      children: [
                        // Edit/Save/Cancel Buttons
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
                                  backgroundColor: const Color(0xFF2563EB), // blue-600
                                )
                              else ...[
                                _buildButton(
                                  onPressed: _handleSave,
                                  text: 'Save',
                                  icon: Icons.save,
                                  backgroundColor: const Color(0xFF16A34A), // green-600
                                ),
                                const SizedBox(width: 8),
                                _buildButton(
                                  onPressed: _handleCancel,
                                  text: 'Cancel',
                                  icon: Icons.close,
                                  backgroundColor: Colors.transparent,
                                  textColor: const Color(0xFF6B7280), // gray-500
                                  borderColor: const Color(0xFFD1D5DB), // gray-300
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Profile Photo and Name
                        Padding(
                          padding: const EdgeInsets.only(top: 32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 136,
                                  height: 136,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFFF97316)], // blue-500 to orange-500
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 64,
                                    backgroundImage: NetworkImage(currentProfile.profileImage),
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
                                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                            border: OutlineInputBorder(),
                                          ),
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  ),

                  const SizedBox(height: 16),

                  // --- About Me Section ---
                  _buildCard(
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
                                style: const TextStyle(color: Color(0xFF374151)), // gray-700
                              )
                            : Text(
                                currentProfile.aboutMe,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151), // gray-700
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Preferred Genres Section ---
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Preferred Genres', const Color(0xFFF97316)), // orange-500
                        const SizedBox(height: 12),

                        // Top Genre Highlight
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _isEditing
                              ? SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _topGenreController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      hintText: 'Top genre',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFFF97316)], // blue-600 to orange-500
                                    ),
                                  ),
                                  child: Text(
                                    '⭐ ${currentProfile.topGenre}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),

                        // Genre Tags
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ...currentProfile.preferredGenres.map((genre) => Container(
                                  padding: EdgeInsets.only(left: 12, right: _isEditing ? 4 : 12, top: 6, bottom: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF), // blue-50
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF93C5FD)), // blue-300
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        genre,
                                        style: const TextStyle(
                                          color: Color(0xFF1D4ED8), // blue-700
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
                                              color: Color(0xFFDC2626), // red-600
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )),
                            if (_isEditing)
                              SizedBox(
                                width: 120,
                                height: 32,
                                child: TextField(
                                  controller: _newGenreController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add genre...',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: _addGenre,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Game Collection Summary ---
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader('My Collection', const Color(0xFFFBBF24)), // yellow-500
                            _isEditing
                                ? SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _ownedGamesCountController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        _editedProfile = _editedProfile.copyWith(
                                          ownedGamesCount: int.tryParse(value) ?? 0,
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFEF3C7), Color(0xFFFEEADF)], // yellow-100 to orange-100
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

                        // Horizontal Scrollable Game Grid
                        SizedBox(
  height: 180,
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var game in currentProfile.favoriteGames)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GameCard(game: game),
          ),
      ],
    ),
  ),
),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Logout Button ---
                  _buildCard(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.onLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // red-600
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Logout', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for the Game Cards
class GameCard extends StatelessWidget {
  final FavoriteGame game;

  const GameCard({Key? key, required this.game}) : super(key: key);

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