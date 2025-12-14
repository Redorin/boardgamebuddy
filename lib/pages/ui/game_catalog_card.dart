import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/board_game.dart';

class GameCatalogCard extends StatelessWidget {
  final BoardGame game;
  final bool isSelected;

  const GameCatalogCard({
    required this.game,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 3)
            : Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 12 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  game.thumbnailUrl.isEmpty
                      ? 'https://via.placeholder.com/300'
                      : game.thumbnailUrl,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: Center(
                      child: Icon(
                        Icons.category,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(5.0, 3.0, 5.0, 3.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  game.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${game.minPlayers}-${game.maxPlayers}p',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          height: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${game.playerTime}m',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        height: 1.0,
                      ),
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
