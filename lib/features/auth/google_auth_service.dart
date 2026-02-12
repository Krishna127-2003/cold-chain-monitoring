// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Correct constructor for v7.x
  static final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: ['email', 'profile'],
  );

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? user =
          await _googleSignIn.signIn();

      if (user == null) return null;

      final GoogleSignInAuthentication auth =
          await user.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        // ✅ accessToken REMOVED in v7 — Firebase doesn't need it anymore
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In failed: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static bool isLoggedIn() => _auth.currentUser != null;

  static User? currentUser() => _auth.currentUser;
}
