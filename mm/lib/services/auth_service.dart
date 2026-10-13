import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuthentication = googleUser.authentication;
      final idToken = googleAuthentication.idToken;

      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebaseAuth.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
