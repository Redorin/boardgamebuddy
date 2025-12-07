import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // 💡 CHANGED: Renamed usernameCtrl to emailCtrl
  final emailCtrl = TextEditingController(); 
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  
  String error = "";
  bool isLoading = false;

  @override
  void dispose() {
    emailCtrl.dispose(); // 💡 CHANGED: Dispose emailCtrl
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      error = "";
      isLoading = true;
    });

    // 1. Client-side Validation (Unchanged)
    if (passwordCtrl.text != confirmPasswordCtrl.text) {
        setState(() {
          error = "Passwords do not match!";
          isLoading = false;
        });
        return;
    }

    if (passwordCtrl.text.length < 6) {
      setState(() {
        error = "Password must be at least 6 characters.";
        isLoading = false;
      });
      return;
    }

    // 2. Server-side Registration
    // 💡 CHANGED: Passing emailCtrl.text instead of the old usernameCtrl.text
    bool ok = await AuthService.register(
      emailCtrl.text, // Now passing the email
      passwordCtrl.text,
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        // 💡 CHANGED: Updated error message for email-based registration
        error = "Registration failed. Email may be invalid or already in use."; 
        isLoading = false;
      });
    } else {
      // Navigate to Login on success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1B1C1E),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            width: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xff2A2C2E),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  )
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign up to get started",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // 💡 CHANGED: Email Input (previously Username)
                TextField(
                  controller: emailCtrl, // 💡 CHANGED CONTROLLER
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Email", // 💡 CHANGED HINT
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xff3A3C3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Password Input (Unchanged)
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xff3A3C3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Password Input (Unchanged)
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xff3A3C3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // Error Message (Unchanged)
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),

                // Sign Up Button (Unchanged logic, now using email)
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: Colors.deepPurple.withOpacity(0.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                ),

                const SizedBox(height: 16),

                // Login Link (Unchanged)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {
                          Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginPage()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}