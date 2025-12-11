// lib/pages/home_page.dart (MODERN COLOR SCHEME)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/app_theme.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import '../models/board_game.dart';
import 'player_finder.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'my_collection.dart';
import 'ui/game_detail_drawer.dart';

class HomePage extends StatefulWidget {
  final String initialUsername;
  const HomePage(this.initialUsername, {Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    //ProfileService.updateCurrentLocation();
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
        return ProfilePage(
          onLogout: _handleLogout,
          onDisplayNameUpdate: (_) {},
        );
      default:
        return const DiscoverPage();
    }
  }

  AppBar? _getAppBar() {
    return null; // All headers removed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _getAppBar(),
      body: _getPage(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // keep 10-15px from screen edges
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textTertiary,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: AnimatedScale(
                      scale: _selectedIndex == 0 ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: const Icon(Icons.search),
                    ),
                    label: "Discover",
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedScale(
                      scale: _selectedIndex == 1 ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: const Icon(Icons.collections),
                    ),
                    label: "Collection",
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedScale(
                      scale: _selectedIndex == 2 ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: const Icon(Icons.group),
                    ),
                    label: "Friends",
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedScale(
                      scale: _selectedIndex == 3 ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: const Icon(Icons.person),
                    ),
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
        ),
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
          return const Center(
            child: Text(
              "No games available",
              style: TextStyle(color: Colors.white),
            ),
          );
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
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Discover new worlds",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textTertiary,
                    ),
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

                    // Use AnimatedBuilder so the card rebuilds as the PageController's
                    // page value changes (smooth transform during scroll/animation).
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        final double page =
                            (_pageController.hasClients &&
                                _pageController.page != null)
                            ? _pageController.page!
                            : _pageController.initialPage.toDouble();

                        final double pageDelta = page - index;
                        final double distortion = (1 - (pageDelta.abs() * 0.3))
                            .clamp(0.0, 1.0);
                        final double rotation = pageDelta * -0.2;

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(rotation)
                            ..scale(distortion),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
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
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                  size: 30,
                ),
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
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textPrimary,
                  size: 30,
                ),
                onPressed: _goToNextPage,
                splashRadius: 20,
              ),
            ),

            // Hint Text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Swipe or Click arrows to explore",
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                game.thumbnailUrl.isEmpty
                    ? 'https://via.placeholder.com/400'
                    : game.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  color: AppColors.surface,
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.textSecondary,
                  ),
                ),
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
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag(LucideIcons.shapes, game.category),
                        const SizedBox(width: 10),
                        _buildTag(LucideIcons.timer, "${game.playerTime} min"),
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
          Icon(icon, color: AppColors.textPrimary, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// GameDetailDrawer is now in ui/game_detail_drawer.dart
