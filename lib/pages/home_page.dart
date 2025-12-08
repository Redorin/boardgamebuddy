import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_service.dart';
import 'add_game.dart';
import 'player_finder.dart';
import 'profile_page.dart'; // 💡 NEW IMPORT
import 'login_page.dart'; // Required for logout navigation

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
  }
  
  // 💡 LOGOUT HANDLER
  void _handleLogout() {
    // 1. In a real app, call a service to sign out of Firebase
    // AuthService.logout(); 

    // 2. Navigate back to the LoginPage and clear the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage() {
    switch (_selectedIndex) {
      case 0:
        return DiscoverPage();
      case 1:
        // Pass the username to the Collection Page
        return MyCollectionPage(_username); 
      case 2:
        return PlayerFinderPage(); 
      case 3:
        // 💡 UPDATED: Pass the onLogout callback to the new ProfilePage
        return ProfilePage(
          onLogout: _handleLogout, 
        );
      default:
        return DiscoverPage();
    }
  }

  AppBar _getAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: Text("Discover", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        );
      case 1:
        return AppBar(
          title: Text("My Collection", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        );
      case 2:
        return AppBar(
          title: Text("Friends", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        );
      case 3:
        // 💡 UPDATED: Title change for the new Profile page
        return AppBar(
          title: Text("My Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), 
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        );
      default:
        return AppBar(
          title: Text("App", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: _getAppBar(),
      body: _getPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff1E1E1E),
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

// ------------------- Discover Page -------------------
class DiscoverPage extends StatelessWidget {
  final List<String> sampleGames = [
    "Catan",
    "Carcassonne",
    "Ticket to Ride",
    "Pandemic",
    "Chess"
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: sampleGames.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 2,
        ),
        itemBuilder: (context, index) {
          return Card(
            color: const Color(0xff1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text(
                sampleGames[index],
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------- My Collection Page -------------------
class MyCollectionPage extends StatelessWidget { 
  final String username;
  const MyCollectionPage(this.username, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: GameService.getGamesStream(username),
              builder: (context, snapshot) {
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final games = snapshot.data ?? [];
                
                if (games.isEmpty) {
                  return Center(
                    child: Text(
                      "No games added yet",
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (_, i) {
                    return Card(
                      color: const Color(0xff1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          games[i], 
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () { 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddGamePage(username),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                "Add Game",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// NOTE: PlayerFinderPage should be imported from its own file (lib/pages/player_finder.dart)
// and is not included here for brevity, but should remain in your project.