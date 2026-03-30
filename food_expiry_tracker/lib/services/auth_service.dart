import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      return result.user;
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  static Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
