import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_service.dart';
import 'add_game.dart';
import 'player_finder.dart';

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
        return MyCollectionPage(_username);
      case 2:
        return PlayerFinderPage();
      case 3:
        return ProfilePage(
          _username,
          onUsernameChanged: (newUsername) {
            setState(() {
              _username = newUsername;
            });
          },
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

// ------------------- My Collection Page -------------------
class MyCollectionPage extends StatefulWidget {
  final String username;
  const MyCollectionPage(this.username);

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState();
}

class _MyCollectionPageState extends State<MyCollectionPage> {
  @override
  Widget build(BuildContext context) {
    final games = GameService.getGames(widget.username);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: games.isEmpty
                ? Center(
                    child: Text(
                      "No games added yet",
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
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
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddGamePage(widget.username),
                  ),
                );
                setState(() {});
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

// ------------------- Profile Page -------------------
class ProfilePage extends StatefulWidget {
  final String username;
  final Function(String) onUsernameChanged;

  const ProfilePage(this.username, {required this.onUsernameChanged, Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _usernameCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Edit Username",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Username",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xff2A2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.person, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onUsernameChanged(_usernameCtrl.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Username updated!"),
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          )
        ],
      ),
    );
  }
}
