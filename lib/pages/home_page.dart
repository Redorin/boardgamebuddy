// lib/pages/home_page.dart (FINAL CORRECTED CODE)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_service.dart';
import 'player_finder.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'my_collection.dart'; 
import '../services/auth_service.dart';
import '../services/profile_service.dart'; // <--- ADDED: ProfileService import

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
    
    // 💡 GEOLOCATION INTEGRATION: Update user's location upon launch
    ProfileService.updateCurrentLocation(); 
  }
  
  // LOGOUT HANDLER
  void _handleLogout() async { 
    // 1. Call the service to sign out of Firebase
    await AuthService.logout(); 

    // 2. Navigate back to the LoginPage and clear the navigation stack
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
        return DiscoverPage();
      case 1:
        // MyCollectionPage no longer requires arguments
        return const MyCollectionPage(); 
      case 2:
        return const PlayerFinderPage(); 
      case 3:
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
        return AppBar(
          title: Text("Welcome, $_username", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), 
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
// NOTE: The MyCollectionPage class definition must be present in its imported file (my_collection.dart).