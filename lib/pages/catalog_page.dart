// lib/pages/catalog_page.dart (FINAL: IMPLEMENTS FILTERING BY COLLECTION)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/board_game.dart';
import '../services/game_service.dart';

// Reusable card widget for the catalog
class GameCatalogCard extends StatelessWidget {
  final BoardGame game;
  final bool isSelected;
  
  const GameCatalogCard({
    required this.game,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: isSelected 
            ? Border.all(color: Colors.deepPurpleAccent, width: 3)
            : null, 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  game.thumbnailUrl.isEmpty ? 'https://via.placeholder.com/300' : game.thumbnailUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120, width: double.infinity, color: Colors.grey,
                    child: const Center(child: Icon(Icons.category, color: Colors.white70)),
                  ),
                ),
              ),
              if (isSelected)
                const Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.check_circle, color: Colors.deepPurpleAccent, size: 28),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(game.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${game.minPlayers}-${game.maxPlayers} players', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${game.playerTime} min', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({Key? key}) : super(key: key);

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Stores the IDs of selected games
  Set<String> _selectedGameIds = {}; 

  void _toggleGameSelection(BoardGame game) {
    setState(() {
      if (_selectedGameIds.contains(game.id)) {
        _selectedGameIds.remove(game.id);
      } else {
        _selectedGameIds.add(game.id);
      }
    });
  }
  
  void _addSelectedGames() async {
    if (_selectedGameIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one game.')),
      );
      return;
    }
    
    // 1. Call service to add all selected games (Triggers counter cache update)
    await GameService.addGamesByIds(_selectedGameIds.toList());
    
    if (mounted) {
      // 2. Return to the Collection Page
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 LAYER 1: Stream the IDs of games the user already owns.
    return StreamBuilder<Set<String>>(
      stream: GameService.getUserCollectionIds(),
      builder: (context, ownedIdsSnapshot) {
        final Set<String> ownedIds = ownedIdsSnapshot.data ?? {};
        
        // LAYER 2: Stream the entire game catalog.
        return StreamBuilder<List<BoardGame>>(
          stream: GameService.getAllCatalogGames(),
          builder: (context, catalogSnapshot) {
            
            if (catalogSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (catalogSnapshot.hasError) {
              return Center(child: Text('Error loading catalog: ${catalogSnapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            
            final List<BoardGame> allGames = catalogSnapshot.data ?? [];
            
            // 💡 FILTERING STEP: Remove games whose IDs are in the ownedIds set.
            final List<BoardGame> filteredGames = allGames.where((game) {
              return !ownedIds.contains(game.id);
            }).toList();

            return Scaffold(
              backgroundColor: const Color(0xFF0E141B),
              appBar: AppBar(
                title: Text("Game Catalog (${filteredGames.length})", style: GoogleFonts.poppins()),
                backgroundColor: const Color(0xFF171A21),
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  Center(
                    child: Text(
                      "${_selectedGameIds.length} Selected",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: _addSelectedGames,
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    tooltip: 'Add Selected Games',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: filteredGames.isEmpty
                  ? Center(child: Text(ownedIds.isEmpty ? "No games available in catalog." : "You own every game in the catalog!", style: const TextStyle(color: Colors.white54, fontSize: 16)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: filteredGames.length,
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
                        final isSelected = _selectedGameIds.contains(game.id);
                        
                        return GestureDetector(
                          onTap: () => _toggleGameSelection(game),
                          child: GameCatalogCard(
                            game: game,
                            isSelected: isSelected,
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
}