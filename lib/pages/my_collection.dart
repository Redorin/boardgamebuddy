// lib/pages/my_collection.dart (TRANSLATED DESIGN)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Using lucide_icons for icons like Search, Sliders, etc.
import '../services/game_service.dart';
import '../models/board_game.dart'; 
import 'catalog_page.dart';

class MyCollectionPage extends StatelessWidget { 
  const MyCollectionPage({super.key}); 

  @override
  Widget build(BuildContext context) {
    // The main background color from the React component's background: #0e141b
    const Color primaryBackgroundColor = Color(0xFF0E141B);
    
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      // We are moving the header logic into the body as a custom scroll view
      // because the design needs a sticky, complex header separate from the AppBar.
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              // Using a flexible space to embed the CollectionsHeader design
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

  // --- Header Component Translation ---
  Widget _buildCollectionsHeader(BuildContext context) {
    // Colors based on React/Tailwind component
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
                    child: const TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search your collection...",
                        hintStyle: TextStyle(color: grayText, fontSize: 14),
                        prefixIcon: Icon(LucideIcons.search, size: 16, color: grayText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filters and View Toggles
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      // Filters Button
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: borderColor, // Active state
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(LucideIcons.layoutGrid, size: 16, color: Colors.white),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(LucideIcons.list, size: 16, color: grayText),
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

  // --- Game Grid Component Translation (Updates the counter display) ---
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
        
        if (games.isEmpty) {
          return Center(
            child: Text(
              "Your collection is empty. Add some games!",
              style: GoogleFonts.poppins(color: const Color(0xFF8F98A0), fontSize: 16),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Count Indicator - Now uses actual stream data
              Text(
                "${games.length} games in collection", 
                style: const TextStyle(color: Color(0xFF8F98A0), fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // Responsive Game Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Default for small screen
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2 / 3, // Matches the aspect ratio in the React code
                  ),
                  itemCount: games.length,
                  itemBuilder: (_, i) {
                    return _buildGameCard(games[i]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- Game Card Component Translation ---
  Widget _buildGameCard(BoardGame game) {
    // Card styling to match the dark theme and hover effect intent
    return InkWell(
      onTap: () {
        // TODO: Implement navigation to Game Detail Page
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
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF8F98A0)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Color(0xFF8F98A0), fontSize: 10)),
      ],
    );
  }
}