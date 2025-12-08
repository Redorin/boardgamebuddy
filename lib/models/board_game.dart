// lib/models/board_game.dart

class BoardGame {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int minPlayers;
  final int maxPlayers;
  final int playingTime;

  BoardGame({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playingTime,
  });

  // Method to convert this object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'playingTime': playingTime,
    };
  }
}