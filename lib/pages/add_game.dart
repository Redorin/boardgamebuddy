import 'package:flutter/material.dart';
import '../services/game_service.dart';

class AddGamePage extends StatelessWidget {
  final String username;
  AddGamePage(this.username);

  final gameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1B1C1E),
      appBar: AppBar(
        title: const Text("Add Game"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: gameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Game Name",
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xff3A3C3E),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                GameService.addGame(username, gameCtrl.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text("Add"),
            )
          ],
        ),
      ),
    );
  }
}
