import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
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
