// lib/pages/add_game.dart (CORRECTED)
import 'package:flutter/material.dart';
import '../services/game_service.dart';

class AddGamePage extends StatelessWidget {
  // 💡 FIX: The 'const' keyword was REMOVED from the constructor.
  // This allows the non-constant field 'gameCtrl' to be initialized.
  AddGamePage({super.key}); 

  final gameCtrl = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    // Note: The UI logic here is assumed to be correct based on previous snippets.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Game"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: gameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter game name",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Call the asynchronous service method without the username parameter
                GameService.addGame(gameCtrl.text.trim());
                
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Add",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}