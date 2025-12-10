// lib/pages/catalog_page.dart (NEW FILE)
import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../services/game_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        title: const Text("Game Catalog"),
        backgroundColor: Colors.deepPurpleAccent,
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
      body: StreamBuilder<List<BoardGame>>(
        // Fetches ALL games from the global '/games' collection
        stream: GameService.getAllCatalogGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading catalog: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final games = snapshot.data ?? [];
          if (games.isEmpty) {
            return const Center(child: Text("No games found in the catalog.", style: TextStyle(color: Colors.white54)));
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final isSelected = _selectedGameIds.contains(game.id);
              
              return GestureDetector(
                onTap: () => _toggleGameSelection(game),
                child: GameCatalogCard(
                  game: game,
                  isSelected: isSelected,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
  
  // ✅ FIX: Return 'null' or a transparent Border.all()
  border: isSelected 
      ? Border.all(color: Colors.deepPurpleAccent, width: 3)
      : null, 
),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image Placeholder
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
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey,
                    child: const Center(child: Icon(Icons.category, color: Colors.white70)),
                  ),
                ),
              ),
              // Selection Indicator
              if (isSelected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle, color: Colors.deepPurpleAccent, size: 28),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${game.minPlayers}-${game.maxPlayers} players',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${game.playerTime} min',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
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