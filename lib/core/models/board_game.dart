class BoardGame {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int minPlayers;
  final int maxPlayers;
  final int playerTime;
  final String category;

  BoardGame({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playerTime,
    required this.category,
  });

  /// Convert this object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'playerTime': playerTime,
      'category': category,
    };
  }

  /// Factory method to create a BoardGame object from a Firestore document
  factory BoardGame.fromFirestore(Map<String, dynamic> data) {
    final dynamic timeValue = data['playerTime'] ?? data['playingTime'];

    return BoardGame(
      id: data['id'] as String? ?? '0',
      name: data['name'] as String? ?? 'Unknown Game',
      description:
          data['description'] as String? ?? 'No description available.',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      minPlayers: (data['minPlayers'] as int?) ?? 1,
      maxPlayers: (data['maxPlayers'] as int?) ?? 2,
      playerTime: (timeValue as int?) ?? 30,
      category: data['category'] as String? ?? 'Board Game',
    );
  }
}
