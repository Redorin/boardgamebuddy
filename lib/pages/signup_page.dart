import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
@override
State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
const Text("Create Account",
style: TextStyle(fontSize: 20, color: Colors.white)),
const SizedBox(height: 20),
TextField(
controller: usernameCtrl,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
hintText: "Username",
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
filled: true,
fillColor: const Color(0xff3A3C3E),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12)),
),
),
if (error.isNotEmpty)
Text(error, style: const TextStyle(color: Colors.redAccent)),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () async {
bool ok = await AuthService.register(
usernameCtrl.text,
passwordCtrl.text,
);
if (!ok) {
setState(() => error = "Username already taken.");
} else {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => LoginPage()),
);
}
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.deepPurple,
minimumSize: const Size(double.infinity, 48),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12))),
child: const Text("Sign Up"),
),
],
),
),
),
);
}
}
