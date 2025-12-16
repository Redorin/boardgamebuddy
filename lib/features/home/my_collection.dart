// lib/features/home/my_collection.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart'; 
import '../../core/services/game_service.dart';
import '../../core/models/board_game.dart';
import '../../shared/config/app_theme.dart';
import 'catalog_page.dart';
import 'game_detail_page.dart';

enum CollectionViewMode { grid, list }

class MyCollectionPage extends StatefulWidget {
  const MyCollectionPage({super.key});

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState();
}

class _MyCollectionPageState extends State<MyCollectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CollectionViewMode _viewMode = CollectionViewMode.grid;

  Timer? _debounce;
  
  // Define Colors locally to match your design
  static const Color _shimmerBaseColor = Color(0xFF171A21);
  static const Color _shimmerHighlightColor = Color(0xFF2A3F5F);
  static const Color _headerBg = Color(0xFF171A21);
  static const Color _borderColor = Color(0xFF2A3F5F);
  static const Color _inputBg = Color(0xFF0E141B);
  static const Color _grayText = Color(0xFF8F98A0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchQuery != _searchController.text.trim()) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  void _toggleViewMode(CollectionViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- Skeleton Widgets ---

  Widget _buildSkeletonGridCard() {
    return Container(
      decoration: BoxDecoration(
        color: _shimmerBaseColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(child: Container(color: _shimmerHighlightColor)), 
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: _shimmerHighlightColor),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 80, color: _shimmerHighlightColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonListTile() {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: _shimmerBaseColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(width: 60, height: 60, color: _shimmerHighlightColor),
        ),
        title: Container(height: 14, width: 150, color: _shimmerHighlightColor),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(height: 10, width: 100, color: _shimmerHighlightColor),
        ),
      ),
    );
  }

  Widget _buildSkeletonView() {
    return Shimmer.fromColors(
      baseColor: _shimmerBaseColor,
      highlightColor: _shimmerHighlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 150, color: _shimmerHighlightColor),
            const SizedBox(height: 12),
            Expanded(
              child: _viewMode == CollectionViewMode.grid
                  ? GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2 / 3,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, i) => _buildSkeletonGridCard(),
                    )
                  : ListView.builder(
                      itemCount: 6,
                      itemBuilder: (_, i) => _buildSkeletonListTile(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Content ---

  Widget _buildGameGrid() {
    return StreamBuilder<List<BoardGame>>(
      stream: GameService.getUserCollectionGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonView();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final games = snapshot.data ?? [];
        var filteredGames = games.where((game) {
          final query = _searchQuery.toLowerCase();
          return game.name.toLowerCase().contains(query) ||
              game.category.toLowerCase().contains(query);
        }).toList();

        if (filteredGames.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Text(
              "No games found matching '$_searchQuery'.",
              style: GoogleFonts.poppins(color: _grayText, fontSize: 16),
            ),
          );
        } else if (games.isEmpty) {
          return Center(
            child: Text(
              "Your collection is empty. Add some games!",
              style: GoogleFonts.poppins(color: _grayText, fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${filteredGames.length} games in collection",
                style: const TextStyle(color: _grayText, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _viewMode == CollectionViewMode.grid
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 2 / 3,
                        ),
                        itemCount: filteredGames.length,
                        itemBuilder: (_, i) => _buildGameCard(filteredGames[i]),
                      )
                    : ListView.builder(
                        itemCount: filteredGames.length,
                        itemBuilder: (_, i) => _buildGameListTile(filteredGames[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameCard(BoardGame game) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailPage(game: game)),
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E141B),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                game.thumbnailUrl.isEmpty
                    ? 'https://via.placeholder.com/300'
                    : game.thumbnailUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  color: const Color(0xFF171A21),
                  child: Center(
                    child: Text(
                      game.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(LucideIcons.users, '${game.minPlayers}-${game.maxPlayers} Players'),
                      _buildInfoRow(LucideIcons.clock, '${game.playerTime} min'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameListTile(BoardGame game) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailPage(game: game)),
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: const Color(0xFF171A21),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              game.thumbnailUrl.isEmpty ? 'https://via.placeholder.com/60' : game.thumbnailUrl,
              width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(
                width: 60, height: 60,
                color: Colors.grey[700],
                child: const Icon(Icons.category, color: Colors.white54),
              ),
            ),
          ),
          title: Text(
            game.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(game.category, style: const TextStyle(color: _grayText, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildInfoRow(LucideIcons.clock, '${game.playerTime} min'),
                  const SizedBox(width: 12),
                  _buildInfoRow(LucideIcons.users, '${game.minPlayers}-${game.maxPlayers}'),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: _grayText),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _grayText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: _grayText, fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBackgroundColor = Color(0xFF0E141B);
    
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              floating: true,
              backgroundColor: _headerBg,
              elevation: 0,
              // FIX: Use title for the top row so it remains visible and interactive
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Collection",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CatalogPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _borderColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: const Text("Add Game"),
                  ),
                ],
              ),
              // FIX: Use bottom for the search bar so it is not hidden/clipped by FlexibleSpaceBar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60), // Space for search bar + padding
                child: Container(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                  decoration: const BoxDecoration(
                    color: _headerBg,
                    border: Border(bottom: BorderSide(color: _borderColor, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search your collection...",
                            hintStyle: GoogleFonts.poppins(color: _grayText, fontSize: 14),
                            prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.accent),
                            filled: true,
                            fillColor: _inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.accent, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _inputBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleViewMode(CollectionViewMode.grid),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _viewMode == CollectionViewMode.grid ? _borderColor : _inputBg,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    LucideIcons.layoutGrid,
                                    size: 16,
                                    color: _viewMode == CollectionViewMode.grid ? Colors.white : _grayText,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleViewMode(CollectionViewMode.list),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _viewMode == CollectionViewMode.list ? _borderColor : _inputBg,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    LucideIcons.list,
                                    size: 16,
                                    color: _viewMode == CollectionViewMode.list ? Colors.white : _grayText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildGameGrid(),
      ),
    );
  }
}