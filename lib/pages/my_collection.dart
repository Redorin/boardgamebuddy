// lib/pages/my_collection.dart (FINAL - LINKS TO GAME DETAIL PAGE)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/game_service.dart';
import '../models/board_game.dart'; 
import 'catalog_page.dart';
import 'home_page.dart'; // Import to access GameDetailDrawer for Discover/Collection (pre-revert state)
import 'game_detail_page.dart'; // ✅ NEW: Import for the dedicated page

// 💡 NEW: Define the two view modes
enum CollectionViewMode { grid, list } 

class MyCollectionPage extends StatefulWidget { 
  const MyCollectionPage({super.key}); 

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState(); 
}

class _MyCollectionPageState extends State<MyCollectionPage> {
  // --- State Variables ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CollectionViewMode _viewMode = CollectionViewMode.grid; 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);
  }
  
  void _updateSearchQuery() {
    if (_searchQuery != _searchController.text.trim()) {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    }
  }

  void _toggleViewMode(CollectionViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchQuery);
    _searchController.dispose();
    super.dispose();
  }

  // --- Header Component Translation ---
  Widget _buildCollectionsHeader(BuildContext context) {
    const Color headerBg = Color(0xFF171A21);
    const Color borderColor = Color(0xFF2A3F5F);
    const Color inputBg = Color(0xFF0E141B);
    const Color grayText = Color(0xFF8F98A0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Row 1: Title and Add Game Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Collection",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: borderColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: const Text("Add Game"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Search and Filter Buttons
            Row(
              children: [
                // Search Input
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _searchController, 
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search your collection...",
                        hintStyle: const TextStyle(color: grayText, fontSize: 14),
                        prefixIcon: const Icon(LucideIcons.search, size: 16, color: grayText),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filters and View Toggles
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      // Filters Button (To be implemented later)
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.slidersHorizontal, size: 20, color: grayText),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),

                      // Grid/List Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            // Grid Button
                            GestureDetector(
                              onTap: () => _toggleViewMode(CollectionViewMode.grid),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  // Conditional coloring for Grid button
                                  color: _viewMode == CollectionViewMode.grid ? borderColor : inputBg, 
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Icon(LucideIcons.layoutGrid, size: 16, 
                                  color: _viewMode == CollectionViewMode.grid ? Colors.white : grayText
                                ),
                              ),
                            ),
                            // List Button
                            GestureDetector(
                              onTap: () => _toggleViewMode(CollectionViewMode.list),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  // Conditional coloring for List button
                                  color: _viewMode == CollectionViewMode.list ? borderColor : inputBg,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Icon(LucideIcons.list, size: 16, 
                                  color: _viewMode == CollectionViewMode.list ? Colors.white : grayText
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- Game Grid Component Translation (Filters and Renders List/Grid) ---
  Widget _buildGameGrid() {
    return StreamBuilder<List<BoardGame>>(
      stream: GameService.getUserCollectionGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)));
        }

        final games = snapshot.data ?? [];
        
        // Filtering Logic
        var filteredGames = games.where((game) {
          final query = _searchQuery.toLowerCase();
          
          // Filter by name and category (case-insensitive)
          return game.name.toLowerCase().contains(query) || 
                 game.category.toLowerCase().contains(query);
        }).toList();

        if (filteredGames.isEmpty && _searchQuery.isNotEmpty) {
          // Show message if search returns no results
          return Center(
            child: Text(
              "No games found matching '$_searchQuery'.",
              style: GoogleFonts.poppins(color: const Color(0xFF8F98A0), fontSize: 16),
            ),
          );
        } else if (games.isEmpty) {
          // Show message if collection is completely empty
          return Center(
            child: Text(
              "Your collection is empty. Add some games!",
              style: GoogleFonts.poppins(color: const Color(0xFF8F98A0), fontSize: 16),
            ),
          );
        }
        
        // Use filteredGames for display count and grid
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Count Indicator
              Text(
                "${filteredGames.length} games in collection", 
                style: const TextStyle(color: Color(0xFF8F98A0), fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // Conditional rendering for Grid vs. List
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
                        itemBuilder: (_, i) {
                          return _buildGameCard(filteredGames[i]);
                        },
                      )
                    : ListView.builder(
                        // FIX: Use shrinkWrap and physics for NestedScrollView compatibility
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredGames.length,
                        itemBuilder: (_, i) {
                          return _buildGameListTile(filteredGames[i]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- Game Card Component Translation (Grid View Tile) ---
  Widget _buildGameCard(BoardGame game) {
    // Card styling to match the dark theme and hover effect intent
    return InkWell(
      onTap: () {
        // 💡 NEW: Navigate to the full page (GameDetailPage)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailPage(game: game)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E141B), // Fallback if image fails
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Game Image
              Image.network(
                game.thumbnailUrl.isEmpty ? 'https://via.placeholder.com/300' : game.thumbnailUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  color: const Color(0xFF171A21),
                  child: Center(child: Text(game.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
                ),
              ),
              // Gradient Overlay for readability (matches React component)
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
              // Game Info at Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(LucideIcons.users, '${game.minPlayers}-${game.maxPlayers} Players'),
                      _buildInfoRow(LucideIcons.clock, '${game.playingTime} min'),
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
  
  // --- Game List Tile (List View Mode) ---
  Widget _buildGameListTile(BoardGame game) {
    const Color grayText = Color(0xFF8F98A0);

    return InkWell( 
      onTap: () {
        // 💡 NEW: Navigate to the full page (GameDetailPage)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailPage(game: game)),
        );
      },
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
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(
                width: 60, height: 60, 
                color: Colors.grey[700], 
                child: const Icon(Icons.category, color: Colors.white54),
              ),
            ),
          ),
          title: Text(
            game.name, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                game.category,
                style: TextStyle(color: grayText, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row( // Combining time and player count
                children: [
                  _buildInfoRow(LucideIcons.clock, '${game.playingTime} min'),
                  const SizedBox(width: 12),
                  _buildInfoRow(LucideIcons.users, '${game.minPlayers}-${game.maxPlayers}'),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF8F98A0)),
        ),
      ),
    );
  }

  // --- Helper Row (Used by both views) ---
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF8F98A0)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Color(0xFF8F98A0), fontSize: 10)),
      ],
    );
  }

  // --- Main Build Method (Reorganized to use NestedScrollView) ---
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
              expandedHeight: 130.0, 
              pinned: true,
              floating: true,
              backgroundColor: primaryBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _buildCollectionsHeader(context),
              ),
            ),
          ];
        },
        body: _buildGameGrid(),
      ),
    );
  }
}