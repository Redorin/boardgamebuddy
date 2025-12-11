// lib/pages/catalog_page.dart (FINAL: FIXES SCROLL RESET AND IMPLEMENTS FILTERING)
import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../services/game_service.dart';
// Note: Assuming these custom imports exist in your project structure
import '../config/app_theme.dart';
import '../widgets/animations.dart';
import 'ui/game_catalog_card.dart';
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
  
  // Cache the games list to prevent flickering when streaming ownedIds
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
    // 💡 LAYER 1: Stream the IDs of games the user already owns.
    return StreamBuilder<Set<String>>(
      stream: GameService.getUserCollectionIds(),
      builder: (context, ownedIdsSnapshot) {
        final Set<String> ownedIds = ownedIdsSnapshot.data ?? {};
        
        // LAYER 2: Stream the entire game catalog.
        return StreamBuilder<List<BoardGame>>(
          stream: GameService.getAllCatalogGames(),
          builder: (context, catalogSnapshot) {
            
            // Handle Loading and Errors based on the catalog stream
            if (catalogSnapshot.connectionState == ConnectionState.waiting) {
              if (_cachedGames == null) {
                return const Center(child: CircularProgressIndicator());
              }
            } else if (catalogSnapshot.hasError) {
              return Center(child: Text('Error loading catalog: ${catalogSnapshot.error}', style: const TextStyle(color: Colors.red)));
            } else if (catalogSnapshot.hasData) {
              // Cache the full catalog data
              _cachedGames = catalogSnapshot.data;
            }

            final List<BoardGame> allGames = _cachedGames ?? [];
            
            // 💡 FILTERING: Remove games whose IDs are in the ownedIds set.
            final List<BoardGame> filteredGames = allGames.where((game) {
              return !ownedIds.contains(game.id);
            }).toList();

            if (filteredGames.isEmpty && _cachedGames != null) {
              return FadeInWidget(
                child: Center(
                  child: Text(
                    "You own every game in the catalog!",
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.darkBg,
              appBar: CatalogHeader(
                selectedCount: _selectedGameIds.length,
                onAddSelected: _addSelectedGames,
              ),
              body: FadeInWidget(
                child: GridView.builder(
                  // 💡 FIX: Both controller and PageStorageKey are needed for reliable scroll position persistence
                  key: const PageStorageKey<String>('catalogGridView'),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    final isSelected = _selectedGameIds.contains(game.id);

                    // Re-integrating your original custom animation structure
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
              ),
            );
          },
        );
      },
    );
  }
}