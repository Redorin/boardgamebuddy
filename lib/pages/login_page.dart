import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final usernameCtrl = TextEditingController();
final passwordCtrl = TextEditingController();
String error = "";

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xff1B1C1E),
body: Center(
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
Text(
"BoardGame Buddy",
style: GoogleFonts.poppins(
fontSize: 24,
color: Colors.white,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 20),
TextField(
controller: usernameCtrl,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
hintText: "Username",
hintStyle: TextStyle(color: Colors.grey[400]),
filled: true,
fillColor: const Color(0xff3A3C3E),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12)),
),
),
const SizedBox(height: 12),
TextField(
controller: passwordCtrl,
obscureText: true,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
hintText: "Password",
hintStyle: TextStyle(color: Colors.grey[400]),
filled: true,
fillColor: const Color(0xff3A3C3E),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12)),
),
),
const SizedBox(height: 12),
if (error.isNotEmpty)
Text(error,
style: const TextStyle(color: Colors.redAccent)),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () async {
bool ok = await AuthService.login(
usernameCtrl.text,
passwordCtrl.text,
);
if (!ok) {
setState(() => error = "Invalid login.");
} else {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => HomePage(usernameCtrl.text)),
);
}
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.deepPurple,
minimumSize: const Size(double.infinity, 48),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12))),
child: const Text("Login"),
),
const SizedBox(height: 12),
TextButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => SignupPage()),
);
},
child: const Text(
"Don’t have an account? Sign Up",
style: TextStyle(color: Colors.white70),
),
)
],
),
),
),
);
}
}
