import 'package:flutter_test/flutter_test.dart';
import 'package:mm/services/firebase_supabase_token_provider.dart';

void main() {
  group('FirebaseSupabaseTokenProvider', () {
    final fixedNow = DateTime.utc(2026, 10, 14);

    test(
      'returns the unchanged Firebase ID token when required claims match',
      () async {
        final provider = FirebaseSupabaseTokenProvider(
          source: _FakeTokenSource(_snapshot()),
          now: () => fixedNow,
        );

        expect(await provider(), 'firebase-id-token-test-fixture');
      },
    );

    test('returns null when no Firebase user is signed in', () async {
      final provider = FirebaseSupabaseTokenProvider(
        source: _FakeTokenSource(null),
        now: () => fixedNow,
      );

      expect(await provider(), isNull);
    });

    test('rejects a token missing the trusted authenticated role', () async {
      final provider = FirebaseSupabaseTokenProvider(
        source: _FakeTokenSource(
          _snapshot(
            claims: {
              'sub': 'uid-a',
              'aud': 'firebase-project-a',
              'iss': 'https://securetoken.google.com/firebase-project-a',
            },
          ),
        ),
        now: () => fixedNow,
      );

      await expectLater(
        provider(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('trusted authenticated role claim'),
          ),
        ),
      );
    });

    test(
      'force refreshes once to receive a server-issued role claim',
      () async {
        final source = _SequenceTokenSource([
          _snapshot(
            claims: {
              'sub': 'uid-a',
              'aud': 'firebase-project-a',
              'iss': 'https://securetoken.google.com/firebase-project-a',
            },
          ),
          _snapshot(),
        ]);
        final provider = FirebaseSupabaseTokenProvider(
          source: source,
          now: () => fixedNow,
        );

        expect(await provider(), 'firebase-id-token-test-fixture');
        expect(source.forceRefreshCalls, [false, true]);
      },
    );

    test('rejects subject, issuer, audience, and expiry mismatches', () async {
      final invalidSnapshots = [
        _snapshot(claims: _validClaims()..['sub'] = 'different-user'),
        _snapshot(claims: _validClaims()..['aud'] = 'other-project'),
        _snapshot(claims: _validClaims()..['iss'] = 'unexpected-issuer'),
        _snapshot(expirationTime: fixedNow),
      ];

      for (final snapshot in invalidSnapshots) {
        final provider = FirebaseSupabaseTokenProvider(
          source: _FakeTokenSource(snapshot),
          now: () => fixedNow,
        );
        await expectLater(provider(), throwsA(isA<StateError>()));
      }
    });
  });
}

Map<String, dynamic> _validClaims() => {
  'sub': 'uid-a',
  'aud': 'firebase-project-a',
  'iss': 'https://securetoken.google.com/firebase-project-a',
  'role': 'authenticated',
};

FirebaseTokenSnapshot _snapshot({
  Map<String, dynamic>? claims,
  DateTime? expirationTime,
}) => FirebaseTokenSnapshot(
  uid: 'uid-a',
  projectId: 'firebase-project-a',
  token: 'firebase-id-token-test-fixture',
  claims: claims ?? _validClaims(),
  expirationTime: expirationTime ?? DateTime.utc(2026, 10, 14, 1),
);

class _FakeTokenSource implements FirebaseTokenSource {
  const _FakeTokenSource(this.snapshot);

  final FirebaseTokenSnapshot? snapshot;

  @override
  Future<FirebaseTokenSnapshot?> currentToken({
    bool forceRefresh = false,
  }) async => snapshot;
}

class _SequenceTokenSource implements FirebaseTokenSource {
  _SequenceTokenSource(this.snapshots);

  final List<FirebaseTokenSnapshot?> snapshots;
  final List<bool> forceRefreshCalls = [];
  var _nextIndex = 0;

  @override
  Future<FirebaseTokenSnapshot?> currentToken({
    bool forceRefresh = false,
  }) async {
    forceRefreshCalls.add(forceRefresh);
    final index = _nextIndex < snapshots.length
        ? _nextIndex++
        : snapshots.length - 1;
    return snapshots[index];
  }
}
