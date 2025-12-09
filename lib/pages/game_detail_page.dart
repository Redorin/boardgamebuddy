// lib/pages/game_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/game_service.dart';
import '../models/board_game.dart'; 

class GameDetailPage extends StatelessWidget {
  final BoardGame game;
  const GameDetailPage({required this.game, super.key});

  // Helper method for the status cards
  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(game.name, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                game.thumbnailUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // Title and Description
            Text(game.name, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(game.description, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54, height: 1.5)),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard(LucideIcons.users, "Players", "${game.minPlayers}-${game.maxPlayers}", Colors.blue),
                _buildStatCard(LucideIcons.timer, "Play Time", "${game.playingTime} min", Colors.purple),
                _buildStatCard(LucideIcons.shapes, "Genre", game.category, Colors.orange),
                _buildStatCard(LucideIcons.zap, "Difficulty", "Medium", Colors.green),
              ],
            ),
            const SizedBox(height: 32),

            // Dynamic Add/Remove Button
            StreamBuilder<bool>(
              stream: GameService.isGameOwned(game.id),
              builder: (context, snapshot) {
                final isOwned = snapshot.data ?? false;
                
                return ElevatedButton.icon(
                  onPressed: () async {
                    if (isOwned) {
                      // REMOVE
                      await GameService.removeGameById(game.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${game.name} removed from collection!"), backgroundColor: Colors.redAccent));
                    } else {
                      // ADD
                      await GameService.addGamesByIds([game.id]);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${game.name} added to collection!"), backgroundColor: Colors.green));
                    }
                    // After action, navigate back
                    if (context.mounted) Navigator.pop(context); 
                  },
                  icon: Icon(isOwned ? Icons.remove_circle : Icons.add_circle, color: Colors.white),
                  label: Text(
                    isOwned ? "Remove from Collection" : "Add to Collection", 
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned ? const Color(0xFFDC2626) : Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50), // Full width
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}