import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseTokenSnapshot {
  const FirebaseTokenSnapshot({
    required this.uid,
    required this.projectId,
    required this.token,
    required this.claims,
    required this.expirationTime,
  });

  final String uid;
  final String projectId;
  final String? token;
  final Map<String, dynamic> claims;
  final DateTime expirationTime;
}

abstract interface class FirebaseTokenSource {
  Future<FirebaseTokenSnapshot?> currentToken();
}

class FirebaseSupabaseTokenProvider {
  FirebaseSupabaseTokenProvider({
    required this.source,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  factory FirebaseSupabaseTokenProvider.firebase({
    FirebaseAuth? auth,
    FirebaseApp? app,
  }) => FirebaseSupabaseTokenProvider(
    source: _FirebaseTokenSource(
      auth ?? FirebaseAuth.instance,
      app ?? Firebase.app(),
    ),
  );

  final FirebaseTokenSource source;
  final DateTime Function() _now;

  Future<String?> call() async {
    final snapshot = await source.currentToken();
    if (snapshot == null) return null;

    final token = snapshot.token;
    if (token == null || token.isEmpty) {
      throw StateError('Firebase did not provide an ID token.');
    }

    if (snapshot.claims['sub'] != snapshot.uid) {
      throw StateError('Firebase ID token subject does not match the user.');
    }
    if (snapshot.claims['aud'] != snapshot.projectId ||
        snapshot.claims['iss'] !=
            'https://securetoken.google.com/${snapshot.projectId}') {
      throw StateError('Firebase ID token issuer or audience is unexpected.');
    }
    if (!snapshot.expirationTime.isAfter(_now())) {
      throw StateError('Firebase ID token has expired.');
    }
    if (snapshot.claims['role'] != 'authenticated') {
      throw StateError(
        'Firebase ID token is missing the trusted authenticated role claim. '
        'Configure a server-side Firebase custom-claims issuer.',
      );
    }

    return token;
  }
}

class _FirebaseTokenSource implements FirebaseTokenSource {
  const _FirebaseTokenSource(this._auth, this._app);

  final FirebaseAuth _auth;
  final FirebaseApp _app;

  @override
  Future<FirebaseTokenSnapshot?> currentToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final projectId = _app.options.projectId;
    if (projectId.isEmpty) {
      throw StateError('Firebase project ID is not configured.');
    }
    final tokenResult = await user.getIdTokenResult();
    if (_auth.currentUser?.uid != user.uid) {
      throw StateError('Firebase account changed while obtaining its token.');
    }
    final expirationTime = tokenResult.expirationTime;
    if (expirationTime == null) {
      throw StateError('Firebase ID token has no expiration time.');
    }

    return FirebaseTokenSnapshot(
      uid: user.uid,
      projectId: projectId,
      token: tokenResult.token,
      claims: tokenResult.claims ?? const {},
      expirationTime: expirationTime,
    );
  }
}
