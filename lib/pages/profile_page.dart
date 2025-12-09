// lib/pages/profile_page.dart (FINAL COMPLETE VERSION)
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/profile_service.dart'; 
import '../services/game_service.dart'; 
import '../models/board_game.dart'; 

// --- Data Models ---

class FavoriteGame {
  final String id;
  final String name;
  final String image;

  FavoriteGame({required this.id, required this.name, required this.image});

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'image': image};
  }

  // Create from Firestore Map
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
  final ImagePicker _picker = ImagePicker(); 
  bool _isUploading = false; 

  // Controllers
  late TextEditingController _displayNameController;
  late TextEditingController _aboutMeController;
  late TextEditingController _topGenreController;
  late TextEditingController _ownedGamesCountController;
  late TextEditingController _newGenreController;

  static const String _defaultProfileImage = 'https://images.unsplash.com/photo-1529995049601-ef63465a463f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXJzb24lMjBwcm9maWxlJTIwcG9ydHJhaXR8ZW58MXx8fHwxNzY1MTQ2MjE0fDA&ixlib=rb-4.1.0&q=80&w=1080';

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

  // --- Logic Methods ---

  Future<void> _handleImagePickAndUpload() async {
    if (!_isEditing) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      // Call the service to upload
      final String? newUrl = await ProfileService.uploadProfileImage(image);

      if (mounted) {
        setState(() {
          _isUploading = false;
          if (newUrl != null) {
            _editedProfile = _editedProfile.copyWith(profileImage: newUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile image updated!"), backgroundColor: Color(0xFF16A34A)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Image upload failed."), backgroundColor: Color(0xFFDC2626)),
            );
          }
        });
      }
    }
  }

  void _handleEdit() {
    setState(() {
      _editedProfile = _profile.copyWith(
        preferredGenres: List.from(_profile.preferredGenres), 
        favoriteGames: List.from(_profile.favoriteGames),
      );
      _displayNameController.text = _editedProfile.displayName;
      _aboutMeController.text = _editedProfile.aboutMe;
      _topGenreController.text = _editedProfile.topGenre;
      _ownedGamesCountController.text = _editedProfile.ownedGamesCount.toString();
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
    );
    
    final favoriteGamesMapList = newProfile.favoriteGames.map((g) => g.toMap()).toList();

    await ProfileService.saveProfileEdits( 
      displayName: newProfile.displayName,
      aboutMe: newProfile.aboutMe,
      preferredGenres: newProfile.preferredGenres,
      topGenre: newProfile.topGenre,
      profileImage: newProfile.profileImage, 
      favoriteGames: favoriteGamesMapList, 
    );
    
    setState(() {
      _profile = newProfile;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated!"), backgroundColor: Color(0xFF16A34A)),
    );
  }

  void _handleCancel() {
    setState(() {
      _editedProfile = _profile.copyWith();
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
      _editedProfile = _editedProfile.copyWith(
        preferredGenres: _editedProfile.preferredGenres.where((g) => g != genreToRemove).toList(),
      );
    });
  }

  void _updateProfileState(Map<String, dynamic> data) async {
    if (data.isNotEmpty) {
      final List<String> genres = (data['preferredGenres'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final int realGameCount = await ProfileService.getOwnedGamesCount();
      
      List<FavoriteGame> fetchedFavorites = [];
      if (data['favoriteGames'] != null) {
        fetchedFavorites = (data['favoriteGames'] as List).map((item) {
          return FavoriteGame.fromMap(item as Map<String, dynamic>);
        }).toList();
      }
      
      if (!_isEditing) {
        setState(() {
          _profile = _profile.copyWith(
            displayName: data['displayName'] as String? ?? _profile.displayName,
            profileImage: data['profileImage'] as String? ?? _defaultProfileImage,
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

  void _showManageFavoritesDialog() async {
    final List<FavoriteGame>? result = await showDialog<List<FavoriteGame>>(
      context: context,
      builder: (context) => ManageFavoritesDialog(
        currentFavorites: _editedProfile.favoriteGames,
      ),
    );

    if (result != null) {
      setState(() {
        _editedProfile = _editedProfile.copyWith(favoriteGames: result);
      });
    }
  }

  // --- UI Builder Methods ---

  Widget _buildHeaderCard(UserProfile currentProfile) {
    return _buildCard(
      child: Stack(
        children: [
          Positioned(
            top: 0, right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEditing) 
                  _buildButton(onPressed: _handleEdit, text: 'Edit Profile', icon: Icons.edit_outlined, backgroundColor: const Color(0xFF2563EB))
                else ...[
                  _buildButton(onPressed: _handleSave, text: 'Save', icon: Icons.save, backgroundColor: const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _buildButton(onPressed: _handleCancel, text: 'Cancel', icon: Icons.close, backgroundColor: Colors.transparent, textColor: const Color(0xFF6B7280), borderColor: const Color(0xFFD1D5DB)),
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
                    onTap: _handleImagePickAndUpload,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 136, height: 136,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFFF97316)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 64,
                            backgroundImage: NetworkImage(currentProfile.profileImage),
                            child: _isUploading ? const CircularProgressIndicator(color: Colors.deepPurpleAccent) : null,
                          ),
                        ),
                        if (_isEditing && !_isUploading)
                          Container(
                            width: 136, height: 136,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.4)),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing 
                    ? SizedBox(width: 250, child: TextField(controller: _displayNameController, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10), border: OutlineInputBorder()), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))) 
                    : Text(currentProfile.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
              ? TextField(controller: _aboutMeController, maxLines: 5, minLines: 3, decoration: InputDecoration(hintText: 'Tell us about yourself...', border: const OutlineInputBorder(), fillColor: Colors.grey[50], filled: true), style: const TextStyle(color: Color(0xFF374151)))
              : Text(currentProfile.aboutMe, style: const TextStyle(fontSize: 16, color: Color(0xFF374151), height: 1.5)),
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
            child: _isEditing
                ? SizedBox(width: 200, child: TextField(controller: _topGenreController, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10), hintText: 'Top genre', border: OutlineInputBorder())))
                : Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFFF97316)])), child: Text('⭐ ${currentProfile.topGenre}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ...currentProfile.preferredGenres.map((genre) => Container(
                padding: EdgeInsets.only(left: 12, right: _isEditing ? 4 : 12, top: 6, bottom: 6),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF93C5FD))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(genre, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 14)),
                    if (_isEditing)
                      InkWell(onTap: () => _removeGenre(genre), borderRadius: BorderRadius.circular(10), child: const Padding(padding: EdgeInsets.only(left: 8.0, right: 4.0), child: Icon(Icons.close, size: 16, color: Color(0xFFDC2626)))),
                  ],
                ),
              )),
              if (_isEditing)
                SizedBox(width: 120, height: 32, child: TextField(controller: _newGenreController, decoration: const InputDecoration(hintText: 'Add genre...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), border: OutlineInputBorder()), onSubmitted: _addGenre)),
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
                ElevatedButton.icon(
                  onPressed: _showManageFavoritesDialog,
                  icon: const Icon(Icons.star, size: 16, color: Colors.black),
                  label: const Text("Manage Top 5", style: TextStyle(color: Colors.black, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFDE047), minimumSize: const Size(0, 32), elevation: 0),
                )
              else
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
                ? const Center(child: Text("No favorites selected", style: TextStyle(color: Colors.grey)))
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

  Widget _buildLogoutButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              elevation: 0,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
  
  // --- Basic Helpers ---
  Widget _buildButton({required VoidCallback onPressed, required String text, required IconData icon, required Color backgroundColor, Color textColor = Colors.white, Color? borderColor}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16.0),
      label: Text(text),
      style: ElevatedButton.styleFrom(foregroundColor: textColor, backgroundColor: backgroundColor, minimumSize: const Size(64, 32), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none), textStyle: const TextStyle(fontSize: 14)),
    );
  }

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
    return StreamBuilder<Map<String, dynamic>>( 
      stream: ProfileService.getUserProfileStream(),
      builder: (context, snapshot) {
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateProfileState(snapshot.data!);
          });
        }

        final currentProfile = _isEditing ? _editedProfile : _profile;

        if (snapshot.connectionState == ConnectionState.waiting && currentProfile.displayName == 'Loading...') {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Colors.transparent, 
          appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 0),
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

// --- Manage Favorites Dialog ---
class ManageFavoritesDialog extends StatefulWidget {
  final List<FavoriteGame> currentFavorites;
  const ManageFavoritesDialog({Key? key, required this.currentFavorites}) : super(key: key);

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
          return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
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
                              if (_selectedIds.length < 5) _selectedIds.add(game.id);
                              else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 5 games allowed"), duration: Duration(milliseconds: 500)));
                            } else {
                              _selectedIds.remove(game.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final List<FavoriteGame> selectedFavorites = myGames
                    .where((game) => _selectedIds.contains(game.id))
                    .map((game) => FavoriteGame(id: game.id, name: game.name, image: game.thumbnailUrl))
                    .toList();
                Navigator.pop(context, selectedFavorites);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              child: const Text("Save Selection", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// --- GameCard ---
class GameCard extends StatelessWidget {
  final FavoriteGame game;
  const GameCard({Key? key, required this.game}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 128, child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Stack(children: [Image.network(game.image, width: 128, height: 160, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], width: 128, height: 160, child: const Center(child: Icon(Icons.broken_image)))), Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.2), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)), alignment: Alignment.bottomLeft, padding: const EdgeInsets.all(8.0), child: Text(game.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))))])));
  }
}