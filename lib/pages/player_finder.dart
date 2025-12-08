// lib/pages/player_finder.dart
import 'package:flutter/material.dart';
import '../services/game_service.dart';

// --- Data Models (Simplified for current Stream structure) ---

// Assuming the stream returns a Map<String, List<String>>
// where the key is the user ID/Name and the value is their game list.
// For the filters, we will use a more detailed local model.

class PlayerDisplay {
  final String id;
  final String displayName;
  final List<String> games;
  // Simplified mock data fields for filtering/sorting
  final double distance;
  final bool isOnline;
  final int gamesOwned;

  PlayerDisplay({
    required this.id,
    required this.displayName,
    required this.games,
    this.distance = 5.0, // Default mock value
    this.isOnline = true,  // Default mock value
    this.gamesOwned = 50, // Default mock value
  });
}

// --- Filter/Sort Enums ---

enum SortOption { distance, active, games }

extension SortOptionExtension on SortOption {
  String get name {
    switch (this) {
      case SortOption.distance:
        return 'Distance (Closest First)';
      case SortOption.active:
        return 'Recently Active';
      case SortOption.games:
        return 'Games Owned (Most First)';
    }
  }
}

// --- Player Finder Component (Stateful Widget) ---

class PlayerFinderPage extends StatefulWidget {
  const PlayerFinderPage({Key? key}) : super(key: key);

  @override
  State<PlayerFinderPage> createState() => _PlayerFinderPageState();
}

class _PlayerFinderPageState extends State<PlayerFinderPage> {
  String _searchQuery = '';
  SortOption _sortBy = SortOption.distance;
  double _maxDistance = 10.0;
  List<String> _selectedGenres = []; // Used for filtering the mocked list
  bool _showOnlineOnly = false;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _clearFilters() {
    setState(() {
      _maxDistance = 10.0;
      _selectedGenres = [];
      _showOnlineOnly = false;
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  // --- Filtering and Sorting Logic ---
  List<PlayerDisplay> _getFilteredAndSortedPlayers(Map<String, List<String>> rawPlayers) {
    List<PlayerDisplay> players = rawPlayers.entries.map((entry) {
      // For this step, we mock the extra fields since the Stream only provides ID and Games.
      // In a real Firebase integration, these fields would come from a UserProfile model.
      return PlayerDisplay(
        id: entry.key,
        displayName: entry.key.split('@').first, // Simple username from email/id
        games: entry.value,
        distance: (entry.key.length % 9) + 1.0, // Mock distance based on key length
        isOnline: (entry.key.length % 2 == 0),
        gamesOwned: entry.value.length * 5,
      );
    }).toList();

    players = players.where((player) {
      // 1. Search filter (by display name or game name)
      final matchesSearch = _searchQuery.isEmpty ||
          player.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          player.games.any((game) => game.toLowerCase().contains(_searchQuery.toLowerCase()));

      // 2. Distance filter
      final matchesDistance = player.distance <= _maxDistance;

      // 3. Online filter
      final matchesOnline = !_showOnlineOnly || player.isOnline;
      
      // NOTE: Genre filter is omitted as the current Stream doesn't provide a list of "preferred genres"

      return matchesSearch && matchesDistance && matchesOnline;
    }).toList();

    // 4. Sort
    players.sort((a, b) {
      switch (_sortBy) {
        case SortOption.distance:
          return a.distance.compareTo(b.distance);
        case SortOption.games:
          return b.gamesOwned.compareTo(a.gamesOwned);
        case SortOption.active:
          // Placeholder for "active". In a real app, this would use a timestamp.
          return a.id.compareTo(b.id);
      }
    });

    return players;
  }
  
  // --- Filter Dialog UI (from previous example, adapted) ---
  Widget _buildFilterDialog() {
    // Local copies of state for the dialog before applying
    SortOption tempSortBy = _sortBy;
    double tempMaxDistance = _maxDistance;
    bool tempShowOnlineOnly = _showOnlineOnly;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Sort',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempMaxDistance = 10.0;
                          tempShowOnlineOnly = false;
                        });
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Colors.white30),

                // Sort By
                const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                DropdownButtonFormField<SortOption>(
                  value: tempSortBy,
                  dropdownColor: Colors.black87,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (SortOption? newValue) {
                    if (newValue != null) setModalState(() => tempSortBy = newValue);
                  },
                  items: SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption value) {
                    return DropdownMenuItem<SortOption>(
                      value: value,
                      child: Text(value.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Proximity Slider
                Text('Within ${tempMaxDistance.round()} miles',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Slider(
                  value: tempMaxDistance,
                  min: 1,
                  max: 25,
                  divisions: 24,
                  label: tempMaxDistance.round().toString(),
                  onChanged: (double value) {
                    setModalState(() => tempMaxDistance = value);
                  },
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white30,
                ),
                const SizedBox(height: 16),

                // Quick Filters
                const Text('Quick Filters', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Row(
                  children: [
                    Checkbox(
                      value: tempShowOnlineOnly,
                      onChanged: (bool? checked) {
                        setModalState(() => tempShowOnlineOnly = checked ?? false);
                      },
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                    ),
                    const Text('Online Now Only', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters and close dialog
                      setState(() {
                        _sortBy = tempSortBy;
                        _maxDistance = tempMaxDistance;
                        _showOnlineOnly = tempShowOnlineOnly;
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 NOTE: Assuming a dark background for the ListTiles based on your original code.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2C), // Dark Blue/Purple
            Color(0xFF0A0A1F), // Very Dark Blue
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Search and Filter Bar ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or game...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent, // Ensure backdrop is transparent
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C), // Dark color for the bottom sheet
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildFilterDialog(),
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- Player List StreamBuilder ---
            Expanded(
              child: StreamBuilder<Map<String, List<String>>>(
                stream: GameService.getAllPlayersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white70));
                  }

                  final rawPlayers = snapshot.data ?? {};
                  final filteredPlayers = _getFilteredAndSortedPlayers(rawPlayers);
                  
                  if (filteredPlayers.isEmpty) {
                    return const Center(
                      child: Text(
                        "No players found matching your criteria.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    );
                  }

                  // Build the list of players
                  return ListView.builder(
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      return _buildPlayerTile(player);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- Reusable Player Tile Widget ---
  Widget _buildPlayerTile(PlayerDisplay player) {
    // 💡 Custom Tile to include more details and match the dark theme
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.05), // Slightly lighter background for the card
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: player.isOnline ? Colors.green : Colors.grey,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              player.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          player.displayName, // Username
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Games: ${player.games.join(", ")}', // List of games
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blueAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${player.distance.toStringAsFixed(1)} mi away',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Icon(player.isOnline ? Icons.circle : Icons.watch_later_outlined, 
                    color: player.isOnline ? Colors.green : Colors.white54, 
                    size: 14),
                const SizedBox(width: 4),
                Text(
                  player.isOnline ? 'Online Now' : 'Offline',
                  style: TextStyle(color: player.isOnline ? Colors.green : Colors.white54, fontSize: 12),
                ),
              ],
            )
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          // TODO: Navigate to player profile
        },
      ),
    );
  }
}