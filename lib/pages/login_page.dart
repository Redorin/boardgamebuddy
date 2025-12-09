// lib/pages/login_page.dart (FINAL ROBUST FOCUS FIX)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for RawKeyboardListener and LogicalKeyboardKey
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController(); 
  final TextEditingController passwordCtrl = TextEditingController();
  
  // 💡 FocusNode for the RawKeyboardListener
  late final FocusNode _focusNode; 

  String error = "";

  @override
  void initState() {
    super.initState();
    // 💡 Must initialize a FocusNode for the RawKeyboardListener
    _focusNode = FocusNode(); 
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    _focusNode.dispose(); 
    super.dispose();
  }

  void handleLogin() async {
    // Prevent multiple submissions while logging in
    if (error == "Logging in...") return; 
    
    setState(() => error = "Logging in...");

    bool ok = await AuthService.login(
      emailCtrl.text,
      passwordCtrl.text,
    );
    
    if (!mounted) return;

    if (!ok) {
      setState(() => error = "Invalid login credentials.");
    } else {
      // Success!
      // NOTE: Using pushReplacement for clean navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(emailCtrl.text),
        ),
      );
    }
  }

  // 💡 Listener function to capture the Enter key press
  void _handleRawKeyEvent(RawKeyEvent event) {
    // Only proceed on a KeyDown event and verify it's the Enter key
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      // Trigger login
      handleLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 NEW: RawKeyboardListener wraps the entire body content
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleRawKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xff1B1C1E),
        body: Center(
          // 💡 NEW: Use a Builder to aggressively request focus on every build
          child: Builder(
            builder: (context) {
              // This is the CRITICAL line: it ensures the RawKeyboardListener always has focus
              if (!_focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_focusNode);
              }
              
              return SingleChildScrollView(
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

                      // Email Field
                      const Text(
                        "Email", 
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailCtrl, 
                        style: const TextStyle(color: Colors.white),
                        // 💡 ADDED: textInputAction to advance the field flow
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey), 
                          hintText: "Enter email address",
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
                      const Text(
                        "Password",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        // 💡 ADDED: textInputAction to signal submission
                        textInputAction: TextInputAction.done,
                        // Keep this for mobile/virtual keyboards
                        //onSubmitted: (_) => handleLogin(),
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
                      if (error.isNotEmpty && error != "Logging in...")
                        Text(
                          error,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      if (error == "Logging in...")
                        const Text(
                          "Logging in...",
                          style: TextStyle(color: Colors.deepPurple),
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
                          child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
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
              );
            }
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