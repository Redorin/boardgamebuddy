import 'package:flutter/material.dart';
import '../../models/board_game.dart';

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
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.deepPurpleAccent.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 12 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey,
                    child: const Center(
                      child: Icon(Icons.category, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              if (isSelected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.deepPurpleAccent,
                    size: 28,
                  ),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${game.playerTime} min',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
