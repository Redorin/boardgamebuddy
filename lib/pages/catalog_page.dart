import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../services/game_service.dart';
import '../config/app_theme.dart';
import '../widgets/animations.dart';
import 'ui/game_catalog_card.dart';
// Add this import
import 'ui/header/catalog_header.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({Key? key}) : super(key: key);

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Stores the IDs of selected games
  Set<String> _selectedGameIds = {};
  late ScrollController _scrollController;
  // Cache the games list to prevent rebuilds on stream re-emission
  List<BoardGame>? _cachedGames;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      backgroundColor: AppColors.darkBg,
      appBar: CatalogHeader(
        selectedCount: _selectedGameIds.length,
        onAddSelected: _addSelectedGames,
      ),
      body: StreamBuilder<List<BoardGame>>(
        stream: GameService.getAllCatalogGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_cachedGames == null) {
              return const Center(child: CircularProgressIndicator());
            }
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading catalog: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            _cachedGames = snapshot.data;
          }

          final games = _cachedGames ?? [];
          if (games.isEmpty) {
            return FadeInWidget(
              child: Center(
                child: Text(
                  "No games found in the catalog.",
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            );
          }

          return FadeInWidget(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.7,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                final isSelected = _selectedGameIds.contains(game.id);

                return SlideUpWidget(
                  duration: AppAnimation.normal,
                  initialOffset: 30.0,
                  child: ScaleInWidget(
                    duration: AppAnimation.normal,
                    initialScale: 0.9,
                    child: TapScaleButton(
                      onTap: () => _toggleGameSelection(game),
                      pressedScale: 0.97,
                      child: GameCatalogCard(
                        game: game,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
