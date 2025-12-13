// lib/features/home/game_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/game_service.dart';
import '../../core/models/board_game.dart';
import '../../shared/config/app_theme.dart';

class GameDetailPage extends StatelessWidget {
  final BoardGame game;
  const GameDetailPage({required this.game, super.key});

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(game.name, style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.darkBgSecondary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                game.thumbnailUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              game.name,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              game.description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
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
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } else {
                      await GameService.addGamesByIds([game.id]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${game.name} added to collection!"),
                          backgroundColor: AppColors.success,
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
                    isOwned ? "Remove from Collection" : "Add to Collection",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned
                        ? AppColors.error
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
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
    );
  }
}
