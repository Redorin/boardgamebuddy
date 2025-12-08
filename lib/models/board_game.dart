// lib/models/board_game.dart
class BoardGame {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int minPlayers;
  final int maxPlayers;
  final int playingTime;
  final String category; // Added for catalog filtering

  BoardGame({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playingTime,
    required this.category, // New field
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
      'category': category,
    };
  }
  
  // Factory method to create a BoardGame object from a Firestore document
  factory BoardGame.fromFirestore(Map<String, dynamic> data) {
  return BoardGame(
    // 🛑 FIX: Use the null-aware operator (??) to provide a fallback empty string or default value.
    id: data['id'] as String? ?? '0', // Fallback ID
    name: data['name'] as String? ?? 'Unknown Game', // Fallback Name
    description: data['description'] as String? ?? 'No description available.',
    thumbnailUrl: data['thumbnailUrl'] as String? ?? '', // Fallback URL
    
    // Non-nullable number fields already have fallbacks, but ensure they handle null:
    minPlayers: (data['minPlayers'] as int?) ?? 1, 
    maxPlayers: (data['maxPlayers'] as int?) ?? 4,
    playingTime: (data['playingTime'] as int?) ?? 60,
    category: data['category'] as String? ?? 'General', // Fallback Category
  );
}
}