// lib/pages/my_collection.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_service.dart';
import 'add_game.dart';

// 💡 CHANGE: MyCollectionPage can be StatelessWidget now, 
// as StreamBuilder handles all the refreshing!
class MyCollectionPage extends StatelessWidget { 
  final String username;
  const MyCollectionPage(this.username, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // ✅ CORE CHANGE: Use StreamBuilder to listen to Firestore
          child: StreamBuilder<List<String>>(
            stream: GameService.getGamesStream(username),
            builder: (context, snapshot) {
              
              // 1. Check for errors
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)));
              }
              
              // 2. Show loading indicator
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 3. Get the data (a list of game names)
              final games = snapshot.data ?? [];
              
              // 4. Build the UI
              if (games.isEmpty) {
                return Center(
                  child: Text(
                    "No games added yet",
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                  ),
                );
              }
              
              // Display the list of game names
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
        // Add Game Button (original code from home_page.dart's MyCollectionPage)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // No need for 'await' or setState, as the StreamBuilder refreshes automatically
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
    );
  }
}