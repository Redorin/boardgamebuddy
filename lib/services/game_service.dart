class GameService {
  // Map<username, List<games>>
  static Map<String, List<String>> _collections = {};

  static List<String> getGames(String username) {
    return _collections[username] ?? [];
  }

  static void addGame(String username, String game) {
    if (!_collections.containsKey(username)) {
      _collections[username] = [];
    }
    _collections[username]!.add(game);
  }

  static Map<String, List<String>> getAllPlayers() {
    return _collections;
  }
}
