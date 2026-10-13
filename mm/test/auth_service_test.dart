import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mm/services/auth_service.dart';

void main() {
  group('AuthService Google sign-in', () {
    test('passes the Google ID token to Firebase credential sign-in', () async {
      final user = _FakeUser('firebase-uid');
      final google = _FakeGoogleGateway('google-id-token');
      final firebase = _FakeFirebaseGateway(user);
      final service = AuthService(
        googleSignInGateway: google,
        firebaseAuthGateway: firebase,
      );

      expect(await service.signInWithGoogle(), isTrue);
      expect(firebase.receivedGoogleIdToken, 'google-id-token');
      expect(service.currentUser?.uid, 'firebase-uid');
    });

    test('treats cancellation as no sign-in and skips Firebase auth', () async {
      final firebase = _FakeFirebaseGateway(_FakeUser('unused'));
      final service = AuthService(
        googleSignInGateway: _FakeGoogleGateway(null),
        firebaseAuthGateway: firebase,
      );

      expect(await service.signInWithGoogle(), isFalse);
      expect(firebase.signInCalls, 0);
    });

    test('propagates Google authentication failures without signing in', () async {
      final firebase = _FakeFirebaseGateway(_FakeUser('unused'));
      final service = AuthService(
        googleSignInGateway: _FakeGoogleGateway.failure(
          const _TestAuthFailure('network unavailable'),
        ),
        firebaseAuthGateway: firebase,
      );

      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<_TestAuthFailure>()),
      );
      expect(firebase.signInCalls, 0);
    });

    test('propagates Firebase credential failures', () async {
      final service = AuthService(
        googleSignInGateway: _FakeGoogleGateway('google-id-token'),
        firebaseAuthGateway: _FakeFirebaseGateway.failure(
          const _TestAuthFailure('credential rejected'),
        ),
      );

      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<_TestAuthFailure>()),
      );
    });
  });
}

class _FakeGoogleGateway implements GoogleSignInGateway {
  _FakeGoogleGateway(this.result) : failure = null;

  _FakeGoogleGateway.failure(this.failure) : result = null;

  final String? result;
  final Object? failure;

  @override
  Future<String?> authenticate() async {
    if (failure case final error?) throw error;
    return result;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeFirebaseGateway implements FirebaseAuthGateway {
  _FakeFirebaseGateway(this.result) : failure = null;

  _FakeFirebaseGateway.failure(this.failure) : result = null;

  final User? result;
  final Object? failure;
  String? receivedGoogleIdToken;
  int signInCalls = 0;

  @override
  Stream<User?> authStateChanges() => Stream.value(result);

  @override
  User? get currentUser => result;

  @override
  Future<User> signInWithGoogleIdToken(String idToken) async {
    signInCalls++;
    receivedGoogleIdToken = idToken;
    if (failure case final error?) throw error;
    return result!;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAuthFailure implements Exception {
  const _TestAuthFailure(this.message);

  final String message;
}
