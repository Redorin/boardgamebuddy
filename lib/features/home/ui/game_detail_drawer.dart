// lib/features/home/ui/game_detail_drawer.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/board_game.dart';
import '../../../core/services/game_service.dart';

class GameDetailDrawer extends StatelessWidget {
  final BoardGame game;
  const GameDetailDrawer({required this.game, super.key});

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
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
                Text(
                  game.name,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      LucideIcons.users,
                      "Players",
                      "${game.minPlayers}-${game.maxPlayers}",
                      Colors.blue,
                    ),
                    _buildStatCard(
                      LucideIcons.timer,
                      "Play Time",
                      "${game.playerTime} min",
                      Colors.purple,
                    ),
                    _buildStatCard(
                      LucideIcons.shapes,
                      "Genre",
                      game.category,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      LucideIcons.zap,
                      "Difficulty",
                      "Medium",
                      Colors.green,
                    ),
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
                          await GameService.removeGameById(game.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${game.name} removed from collection!",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else {
                          await GameService.addGamesByIds([game.id]);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${game.name} added to collection!",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(
                        isOwned ? Icons.remove_circle : Icons.add_circle,
                        color: Colors.white,
                      ),
                      label: Text(
                        isOwned
                            ? "Remove from Collection"
                            : "Add to Collection",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwned
                            ? const Color(0xFFDC2626)
                            : Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
