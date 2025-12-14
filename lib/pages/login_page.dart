// lib/pages/login_page.dart (MODERN COLOR SCHEME)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  late final FocusNode _focusNode;

  String error = "";

  @override
  void initState() {
    super.initState();
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
    if (error == "Logging in...") return;

    setState(() => error = "Logging in...");

    bool ok = await AuthService.login(emailCtrl.text, passwordCtrl.text);

    if (!mounted) return;

    if (!ok) {
      setState(() => error = "Invalid login credentials.");
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(emailCtrl.text)),
      );
    }
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      handleLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleRawKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(
          child: Builder(
            builder: (context) {
              if (!_focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_focusNode);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "BoardGame Buddy",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Welcome back",
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      Text(
                        "Email",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailCtrl,
                        style: TextStyle(color: AppColors.textPrimary),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.primary,
                          ),
                          hintText: "Enter email address",
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Password
                      Text(
                        "Password",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        style: TextStyle(color: AppColors.textPrimary),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppColors.primary,
                          ),
                          hintText: "Enter password",
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      if (error.isNotEmpty && error != "Logging in...")
                        Text(
                          error,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      if (error == "Logging in...")
                        Text(
                          "Logging in...",
                          style: TextStyle(color: AppColors.primary),
                        ),

                      const SizedBox(height: 18),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Divider and Social Buttons
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.surface)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.surface)),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _socialButton(
                        "Google",
                        Icons.circle,
                        const Color(0xFFEA4335),
                        () {
                          debugPrint("Login with Google");
                        },
                      ),
                      const SizedBox(height: 12),
                      _socialButton(
                        "Facebook",
                        Icons.circle,
                        const Color(0xFF1877F2),
                        () {
                          debugPrint("Login with Facebook");
                        },
                      ),
                      const SizedBox(height: 12),
                      _socialButton(
                        "Twitter",
                        Icons.circle,
                        const Color(0xFF1DA1F2),
                        () {
                          debugPrint("Login with Twitter");
                        },
                      ),

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
                        child: Text(
                          "Don't have an account? Sign Up",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
    String text,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.surface.withOpacity(0.5),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
