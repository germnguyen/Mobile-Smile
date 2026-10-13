import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class GoogleSignInGateway {
  Future<String?> authenticate();

  Future<void> signOut();
}

abstract interface class FirebaseAuthGateway {
  Stream<User?> authStateChanges();

  User? get currentUser;

  Future<User> signInWithGoogleIdToken(String idToken);

  Future<void> signOut();
}

class AuthService {
  AuthService({
    FirebaseAuthGateway? firebaseAuthGateway,
    GoogleSignInGateway? googleSignInGateway,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth =
           firebaseAuthGateway ??
           _FirebaseAuthGateway(firebaseAuth ?? FirebaseAuth.instance),
       _googleSignIn =
           googleSignInGateway ??
           _GoogleSignInGateway(googleSignIn ?? GoogleSignIn.instance);

  final FirebaseAuthGateway _firebaseAuth;
  final GoogleSignInGateway _googleSignIn;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<bool> signInWithGoogle() async {
    final idToken = await _googleSignIn.authenticate();
    if (idToken == null) return false;

    await _firebaseAuth.signInWithGoogleIdToken(idToken);
    return true;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}

class _GoogleSignInGateway implements GoogleSignInGateway {
  _GoogleSignInGateway(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> authenticate() async {
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In did not return an ID token.');
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}

class _FirebaseAuthGateway implements FirebaseAuthGateway {
  _FirebaseAuthGateway(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User> signInWithGoogleIdToken(String idToken) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw StateError('Firebase did not return a signed-in user.');
    }
    return user;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
