// lib/pages/my_collection.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_service.dart';
import '../models/board_game.dart'; 
import 'catalog_page.dart'; // <--- NEW IMPORT

class MyCollectionPage extends StatelessWidget { 
  const MyCollectionPage({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            // CORE CHANGE: Streaming List<BoardGame>
            child: StreamBuilder<List<BoardGame>>(
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
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (_, i) {
                    final game = games[i];
                    return Card(
                      color: const Color(0xff1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Image.network(
                          game.thumbnailUrl.isEmpty ? 'https://via.placeholder.com/48' : game.thumbnailUrl,
                          width: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Icon(Icons.category, color: Colors.white70),
                        ),
                        title: Text(
                          game.name, 
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${game.minPlayers}-${game.maxPlayers} players | ${game.playingTime} min',
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Add Game Button 
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // NEW NAVIGATION: Go to CatalogPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CatalogPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                "Add Game",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}