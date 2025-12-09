// lib/pages/home_page.dart (REVERTED TO PRE-DETAIL PAGE STATE)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart'; 
import '../models/board_game.dart';
import 'player_finder.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'my_collection.dart'; 
// The import for game_detail_page.dart is intentionally removed.

class HomePage extends StatefulWidget {
  final String initialUsername;
  const HomePage(this.initialUsername, {Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late String _username; 

  @override
  void initState() {
    super.initState();
    _username = widget.initialUsername;
    ProfileService.updateCurrentLocation(); 
  }
  
  void _handleLogout() async { 
    await AuthService.logout(); 
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage() {
    switch (_selectedIndex) {
      case 0:
        return const DiscoverPage(); 
      case 1:
        return const MyCollectionPage(); 
      case 2:
        return const PlayerFinderPage(); 
      case 3:
        return ProfilePage(onLogout: _handleLogout);
      default:
        return const DiscoverPage();
    }
  }

  AppBar? _getAppBar() {
    if (_selectedIndex == 0) return null; 

    switch (_selectedIndex) {
      case 1:
        return AppBar(title: Text("My Collection", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), backgroundColor: Colors.deepPurpleAccent, elevation: 0);
      case 2:
        return AppBar(title: Text("Friends", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), backgroundColor: Colors.deepPurpleAccent, elevation: 0);
      case 3:
        return AppBar(title: Text("Welcome, $_username", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), backgroundColor: Colors.deepPurpleAccent, elevation: 0);
      default:
        return AppBar(title: Text("App", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), backgroundColor: Colors.deepPurpleAccent, elevation: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0E141B), 
      appBar: _getAppBar(),
      body: _getPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff171A21),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.collections), label: "Collection"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Friends"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// DISCOVER PAGE
// ----------------------------------------------------
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7, initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BoardGame>>(
      stream: GameService.getAllCatalogGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final games = snapshot.data ?? [];
        if (games.isEmpty) {
          return const Center(child: Text("No games available", style: TextStyle(color: Colors.white)));
        }
        
        final virtualItemCount = games.length * 1000; 

        return Stack(
          children: [
            // Background Title
            Positioned(
              top: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Board Games",
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Discover new worlds",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // The Circular/3D Gallery (Primary Content)
            Center(
              child: SizedBox(
                height: 500,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(), 
                  itemCount: virtualItemCount, 
                  itemBuilder: (context, index) {
                    final gameIndex = index % games.length;
                    final game = games[gameIndex];

                    final double pageDelta = (_pageController.hasClients && _pageController.page != null)
                        ? (_pageController.page! - index)
                        : 0.0;
                    
                    final double distortion = (1 - (pageDelta.abs() * 0.3)).clamp(0.0, 1.0);
                    final double rotation = pageDelta * -0.2;

                    return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) 
                          ..rotateY(rotation)
                          ..scale(distortion),
                        alignment: Alignment.center,
                        child: _buildGalleryCard(game),
                    );
                  },
                ),
              ),
            ),
            
            // LEFT Navigation Button (Overlay)
            Positioned(
              left: 0,
              top: 0,
              bottom: 120, 
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                onPressed: _goToPreviousPage,
                splashRadius: 20,
              ),
            ),
            
            // RIGHT Navigation Button (Overlay)
            Positioned(
              right: 0,
              top: 0,
              bottom: 120, 
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                onPressed: _goToNextPage,
                splashRadius: 20,
              ),
            ),

            // Hint Text
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Swipe or Click arrows to explore",
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGalleryCard(BoardGame game) {
    return GestureDetector(
      onTap: () {
        // 💡 REVERTED: Show the bottom sheet drawer
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GameDetailDrawer(game: game),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                game.thumbnailUrl.isEmpty ? 'https://via.placeholder.com/400' : game.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white)),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20, left: 20, right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag(LucideIcons.shapes, game.category),
                        const SizedBox(width: 10),
                        _buildTag(LucideIcons.timer, "${game.playingTime} min"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// ✅ RESTORED: GAME DETAIL DRAWER (Bottom Sheet)
// ----------------------------------------------------
class GameDetailDrawer extends StatelessWidget {
  final BoardGame game;
  const GameDetailDrawer({required this.game, super.key});

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
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
                Text(game.name, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text(game.description, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54, height: 1.5)),
                const SizedBox(height: 24),
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
                        // Close the drawer after action
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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