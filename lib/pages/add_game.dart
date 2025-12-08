// lib/pages/add_game.dart
import 'package:flutter/material.dart';
import '../services/game_service.dart';

class AddGamePage extends StatelessWidget {
  final String username;
  AddGamePage(this.username);

  final gameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // ... (rest of the build method UI remains the same) ...
    
    return Scaffold(
      // ... (UI setup) ...
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ... (TextField) ...
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 💡 CHANGE: Call the asynchronous service method
                GameService.addGame(username, gameCtrl.text.trim());
                
                // Pop the screen after initiating the write operation
                Navigator.pop(context); 
              },
              // ... (rest of button styling) ...
              child: const Text("Add"),
            )
          ],
        ),
      ),
    );
  }
}