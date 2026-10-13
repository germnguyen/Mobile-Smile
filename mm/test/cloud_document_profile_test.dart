import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mm/services/cloud_document_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

void main() {
  group('CloudDocumentService.ensureProfile', () {
    test('sends the current Firebase UID and token through Supabase', () async {
      Map<String, dynamic>? insertedProfile;
      String? authorization;
      final client = _client(
        handler: (request) async {
          insertedProfile = jsonDecode(request.body) as Map<String, dynamic>;
          authorization = request.headers['authorization'];
          return http.Response('', 201, request: request);
        },
      );
      addTearDown(client.dispose);
      final service = CloudDocumentService(
        client: client,
        currentUserId: () => 'firebase-uid-a',
      );

      await service.ensureProfile(_user('firebase-uid-a'));

      expect(insertedProfile?['id'], 'firebase-uid-a');
      expect(insertedProfile?['email'], 'user@example.test');
      expect(authorization, startsWith('Bearer '));
    });

    test('rejects a profile user that differs from the active Firebase UID', () async {
      var requestSent = false;
      final client = _client(
        handler: (request) async {
          requestSent = true;
          return http.Response('', 201, request: request);
        },
      );
      addTearDown(client.dispose);
      final service = CloudDocumentService(
        client: client,
        currentUserId: () => 'firebase-uid-a',
      );

      await expectLater(
        service.ensureProfile(_user('firebase-uid-b')),
        throwsA(isA<StateError>()),
      );
      expect(requestSent, isFalse);
    });

    test('surfaces the server RLS denial without falling back', () async {
      final client = _client(
        handler: (request) async => http.Response(
          jsonEncode({
            'code': '42501',
            'message':
                'new row violates row-level security policy for table "users"',
            'details': 'Unauthorized',
            'hint': null,
          }),
          403,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      );
      addTearDown(client.dispose);
      final service = CloudDocumentService(
        client: client,
        currentUserId: () => 'firebase-uid-a',
      );

      await expectLater(
        service.ensureProfile(_user('firebase-uid-a')),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.code,
            'code',
            '42501',
          ),
        ),
      );
    });
  });
}

SupabaseClient _client({
  required Future<http.Response> Function(http.Request request) handler,
}) => SupabaseClient(
  'https://example.supabase.co',
  'test-publishable-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
  accessToken: () async => 'firebase-token-test-fixture',
  httpClient: MockClient(handler),
);

User _user(String uid) => _FakeUser(uid);

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  String? get email => 'user@example.test';

  @override
  String? get displayName => 'Test user';

  @override
  String? get photoURL => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
