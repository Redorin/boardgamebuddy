// lib/features/home/catalog_page.dart (FINAL: ADDED SEARCH BAR)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/board_game.dart';
import '../../core/services/game_service.dart';
import '../../shared/config/app_theme.dart';
import '../../shared/widgets/animations.dart';
import 'ui/game_catalog_card.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({Key? key}) : super(key: key);

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Stores the IDs of selected games
  Set<String> _selectedGameIds = {};
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
    const Color headerBg = Color(0xFF171A21);
    const Color borderColor = Color(0xFF2A3F5F);
    const Color inputBg = Color(0xFF0E141B);
    const Color grayText = Color(0xFF8F98A0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: const BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Game Catalog",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Action Button
                  ElevatedButton(
                    onPressed: _addSelectedGames,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: borderColor,
                      foregroundColor: Colors.white,
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

            // Row 2: Search Bar with Custom Styling
            TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Search catalog...",
                hintStyle: GoogleFonts.poppins(
                  color: grayText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 16,
                  color: grayText,
                ),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              textInputAction: TextInputAction.search,
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
                          style: const TextStyle(color: Colors.red),
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
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? "You own every game in the catalog!"
                              : "No games found matching '$_searchQuery'",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return GridView.builder(
                      key: const PageStorageKey<String>('catalogGridView'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: filteredGames.length,
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
