// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'shared/config/app_theme.dart';

import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BoardGameBuddy());
}

class BoardGameBuddy extends StatelessWidget {
  const BoardGameBuddy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "BoardGame Buddy",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.darkBg,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBgSecondary,
          elevation: 6,
          shadowColor: AppColors.accent.withOpacity(0.5),
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.accent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: AppColors.accent, size: 24),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.6)),
          contentPadding: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.darkBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          headlineMedium: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),

      // CORE CHANGE: Check Auth State Immediately
      home: StreamBuilder<User?>(
        // Listen to Firebase Auth state changes (real-time stream)
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Connection/Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a retro loading indicator
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'LOADING...',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            );
          }

          // 2. Authenticated State
          if (snapshot.hasData) {
            final user = snapshot.data!;
            // If logged in, pass the user's email/ID to HomePage
            return HomePage(user.email ?? user.uid);
          }

          // 3. Unauthenticated State
          // If no user data is present, show the login screen
          return LoginPage();
        },
      ),
    );
  }
}
