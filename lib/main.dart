// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BoardGameBuddy());
}

class BoardGameBuddy extends StatelessWidget {
  const BoardGameBuddy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "BoardGame Buddy",
      debugShowCheckedModeBanner: false,
      
      // CORE CHANGE: Check Auth State Immediately
      home: StreamBuilder<User?>(
        // Listen to Firebase Auth state changes (real-time stream)
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          // 1. Connection/Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a simple loading indicator while Firebase checks the user's session
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)); 
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