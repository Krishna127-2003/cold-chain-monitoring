// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Keep a single GoogleSignIn instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  /// ✅ GOOGLE SIGN-IN
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // 🔁 Force account chooser if already signed in
      await _googleSignIn.signOut();

      // 🔐 Open Google account picker
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      // ❌ User cancelled
      if (googleUser == null) {
        print("ℹ️ Google Sign-In cancelled by user");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // 🔥 Firebase authentication
      final userCredential =
          await _auth.signInWithCredential(credential);

      print("✅ Google Sign-In success: ${userCredential.user?.email}");
      return userCredential;
    } catch (e, s) {
      print("❌ Google Sign-In Error: $e");
      print(s);
      return null;
    }
  }

  /// 🔥 GOOGLE + FIREBASE SIGN-OUT (FULL REVOKE)
  static Future<void> signOut() async {
    try {
      // 🔌 Google account sign-out
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // 🔥 Firebase sign-out
      await _auth.signOut();

      print("✅ Google & Firebase sign-out complete");
    } catch (e) {
      print("❌ Sign-out error: $e");
    }
  }

  /// 🧠 Helper: check Firebase login state
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// 👤 Helper: current user
  static User? currentUser() {
    return _auth.currentUser;
  }
}
