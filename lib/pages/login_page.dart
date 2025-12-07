import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

// The global signIn function is still redundant, but I'll keep it for now.
// It will be cleaner to put this logic inside AuthService.
Future<void> signIn(String email, String password) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    print('Login error: ${e.message}');
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 💡 CHANGED: Renamed usernameCtrl to emailCtrl
  final TextEditingController emailCtrl = TextEditingController(); 
  final TextEditingController passwordCtrl = TextEditingController();

  String error = "";

  void handleLogin() async {
    // 💡 CHANGED: Using emailCtrl.text instead of usernameCtrl.text
    bool ok = await AuthService.login(
      emailCtrl.text,
      passwordCtrl.text,
    );

    if (!ok) {
      setState(() => error = "Invalid login credentials.");
    } else {
      // Passing the email (or what was used to log in) to the home page
      Navigator.push(
        context,
        MaterialPageRoute(
          // 💡 CHANGED: Using emailCtrl.text
          builder: (context) => HomePage(emailCtrl.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1B1C1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xff2A2C2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "BoardGame Buddy",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // 💡 CHANGED: Email Field (previously Username)
                Text(
                  "Email", // 💡 CHANGED LABEL
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailCtrl, // 💡 CHANGED CONTROLLER
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    // 💡 CHANGED ICON
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey), 
                    hintText: "Enter email address", // 💡 CHANGED HINT
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xff3A3C3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Password
                Text(
                  "Password",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    hintText: "Enter password",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xff3A3C3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                if (error.isNotEmpty)
                  Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent),
                  ),

                const SizedBox(height: 18),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Login"),
                  ),
                ),

                const SizedBox(height: 22),

                // Divider and Social Buttons (unchanged for brevity)
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "Or continue with",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 22),

                _socialButton("Google", Icons.circle, Colors.red, () {
                  debugPrint("Login with Google");
                }),
                const SizedBox(height: 12),
                _socialButton("Facebook", Icons.circle, Colors.blue, () {
                  debugPrint("Login with Facebook");
                }),
                const SizedBox(height: 12),
                _socialButton("Twitter", Icons.circle, Colors.lightBlue, () {
                  debugPrint("Login with Twitter");
                }),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Don’t have an account? Sign Up",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String text, IconData icon, Color iconColor, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xff3A3C3E),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}