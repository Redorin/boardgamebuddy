// lib/pages/catalog_page.dart (FINAL: ADDED SEARCH BAR)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Ensure this is imported
import '../models/board_game.dart';
import '../services/game_service.dart';
import '../config/app_theme.dart';
import '../widgets/animations.dart';
import 'ui/game_catalog_card.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Stores the IDs of selected games
  final Set<String> _selectedGameIds = {};
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Timer? _debounce;

  // Cache the games list to prevent flickering when streaming ownedIds
  List<BoardGame>? _cachedGames;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
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

    // 1. Call service to add all selected games
    await GameService.addGamesByIds(_selectedGameIds.toList());

    if (mounted) {
      // 2. Return to the Collection Page
      Navigator.of(context).pop();
    }
  }

  // Custom Header to match Collection Page style + Back Button + Search
  Widget _buildCatalogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Back Button, Title, and Action Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: AppColors.accent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Game Catalog",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Action Button
                  ElevatedButton(
                    onPressed: _addSelectedGames,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.darkBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: Text("Add (${_selectedGameIds.length})"),
                  ),
                ],
              ),
            ),

            // Row 2: Search Bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search catalog...",
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        children: [
          _buildCatalogHeader(),
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: GameService.getUserCollectionIds(),
              builder: (context, ownedIdsSnapshot) {
                final Set<String> ownedIds = ownedIdsSnapshot.data ?? {};

                return StreamBuilder<List<BoardGame>>(
                  stream: GameService.getAllCatalogGames(),
                  builder: (context, catalogSnapshot) {
                    if (catalogSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      if (_cachedGames == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                    } else if (catalogSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading catalog: ${catalogSnapshot.error}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      );
                    } else if (catalogSnapshot.hasData) {
                      _cachedGames = catalogSnapshot.data;
                    }

                    final List<BoardGame> allGames = _cachedGames ?? [];

                    // Filter Logic: Not Owned AND Matches Search
                    final List<BoardGame> filteredGames = allGames.where((
                      game,
                    ) {
                      final isNotOwned = !ownedIds.contains(game.id);
                      final matchesSearch =
                          _searchQuery.isEmpty ||
                          game.name.toLowerCase().contains(_searchQuery) ||
                          game.category.toLowerCase().contains(_searchQuery);

                      return isNotOwned && matchesSearch;
                    }).toList();

                    if (filteredGames.isEmpty && _cachedGames != null) {
                      return FadeInWidget(
                        child: Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? "You own every game in the catalog!"
                                : "No games found matching '$_searchQuery'",
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      );
                    }

                    return FadeInWidget(
                      child: GridView.builder(
                        key: const PageStorageKey<String>('catalogGridView'),
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              crossAxisSpacing: AppSpacing.lg,
                              mainAxisSpacing: AppSpacing.lg,
                            ),
                        itemCount: filteredGames.length,
                        itemBuilder: (context, index) {
                          final game = filteredGames[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
