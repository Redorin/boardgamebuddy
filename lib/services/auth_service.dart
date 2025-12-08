// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Get the FirebaseAuth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. LOGIN METHOD (using Firebase Email/Password)
  // Accepts email and password as inputs.
  static Future<bool> login(String email, String password) async {
    try {
      // Calls the Firebase service to sign in with the provided credentials.
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If the sign-in is successful, we return true.
      return true;

    } on FirebaseAuthException catch (e) {
      // Print the specific Firebase error for debugging purposes (optional, but helpful)
      print('Firebase Login Error Code: ${e.code}');
      
      // Return false on any Firebase authentication error (e.g., user-not-found, wrong-password)
      return false;

    } catch (e) {
      // Catch any other general errors
      print('General Login Error: $e');
      return false;
    }
  }

  // 2. REGISTER METHOD (using Firebase Email/Password)
  // Accepts email and password as inputs.
  static Future<bool> register(String email, String password) async {
    try {
      // Calls the Firebase service to create a new user.
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If user creation is successful, return true.
      return true;

    } on FirebaseAuthException catch (e) {
      // Print the specific Firebase error (e.g., email-already-in-use, weak-password)
      print('Firebase Registration Error Code: ${e.code}');

      // Return false on failure.
      return false;
      
    } catch (e) {
      print('General Registration Error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await _auth.signOut();
      print('User successfully signed out.');
    } catch (e) {
      print('Logout Error: $e');
      // For simplicity, we don't return false on failure, 
      // as sign out usually succeeds unless there's a serious client issue.
    }
  }
}