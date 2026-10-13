import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mm/services/supabase_storage_service.dart';

void main() {
  final client = SupabaseClient('https://example.supabase.co', 'test-key');
  tearDownAll(client.dispose);

  group('SupabaseStorageService', () {
    test('uses a private bucket with a stable owner/document path', () {
      final service = SupabaseStorageService(
        client: client,
        now: () => DateTime.fromMicrosecondsSinceEpoch(1234),
      );

      expect(SupabaseStorageService.bucket, 'documents');
      expect(
        service.createObjectPath(
          ownerId: 'firebase_UID-1',
          documentId: 'e325cce6-b2fc-4f58-9a17-7189b12cb799',
          fileName: r'C:\fakepath\lecture notes.pdf',
        ),
        'firebase_UID-1/e325cce6-b2fc-4f58-9a17-7189b12cb799/'
        '1234_lecture_notes.pdf',
      );
    });

    test('accepts only supported file types and the 20 MB limit', () {
      SupabaseStorageService.validateFile(
        fileName: 'notes.pdf',
        size: SupabaseStorageService.maxFileSizeBytes,
      );

      expect(
        () => SupabaseStorageService.validateFile(
          fileName: 'notes.exe',
          size: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => SupabaseStorageService.validateFile(fileName: 'notes.pdf', size: 0),
        throwsArgumentError,
      );
      expect(
        () => SupabaseStorageService.validateFile(
          fileName: 'notes.pdf',
          size: SupabaseStorageService.maxFileSizeBytes + 1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsafe path segments and maps MIME types', () {
      final service = SupabaseStorageService(
        client: client,
      );

      expect(
        () => service.createObjectPath(
          ownerId: '../someone-else',
          documentId: 'doc-1',
          fileName: 'notes.pdf',
        ),
        throwsArgumentError,
      );
      expect(
        SupabaseStorageService.mimeType('slides.pptx'),
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      );
    });
  });
}
