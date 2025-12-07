import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'add_game.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Collection"),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: const Color(0xff1B1C1E),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddGamePage(widget.username),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (_, i) {
          return ListTile(
            title: Text(
              games[i],
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
