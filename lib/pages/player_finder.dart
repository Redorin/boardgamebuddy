import 'package:flutter/material.dart';
import '../services/game_service.dart';

class PlayerFinderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final players = GameService.getAllPlayers();

    return Scaffold(
      backgroundColor: const Color(0xff1B1C1E),
      appBar: AppBar(
        title: const Text("Player Finder"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        children: players.entries.map((entry) {
          return ListTile(
            title: Text(
              entry.key,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              entry.value.join(", "),
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }).toList(),
      ),
    );
  }
}
