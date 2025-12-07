import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ensures binding before async calls
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
      home: LoginPage(),
    );
  }
}
