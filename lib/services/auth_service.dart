// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Get the FirebaseAuth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. LOGIN METHOD (using Firebase Email/Password)
  static Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Login Error Code: ${e.code}');
      return false;
    } catch (e) {
      print('General Login Error: $e');
      return false;
    }
  }

  // 2. REGISTER METHOD (using Firebase Email/Password)
  static Future<bool> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Registration Error Code: ${e.code}');
      return false;
    } catch (e) {
      print('General Registration Error: $e');
      return false;
    }
  }

  // 3. LOGOUT METHOD
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      print('User successfully signed out.');
    } catch (e) {
      print('Logout Error: $e');
    }
  }
}