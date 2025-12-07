class AuthService {
// Simple username + password store
static Map<String, String> _users = {};

static Future<bool> register(String username, String password) async {
if (_users.containsKey(username)) return false;
_users[username] = password;
return true;
}

static Future<bool> login(String username, String password) async {
return _users[username] == password;
}
}
