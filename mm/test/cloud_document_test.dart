import 'package:flutter_test/flutter_test.dart';
import 'package:mm/models/cloud_document.dart';
import 'package:mm/struct/document_type.dart';

void main() {
  group('CloudDocument permissions', () {
    CloudDocument documentWithPermission(String? permission) => CloudDocument(
      id: 'document-id',
      ownerId: 'owner-id',
      title: 'Lecture notes',
      documentType: DocumentType.lecture,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      permission: permission,
    );

    test('owner can edit and is identified as owner', () {
      final document = documentWithPermission('owner');

      expect(document.isOwner, isTrue);
      expect(document.canEdit, isTrue);
    });

    test('editor can edit but is not the owner', () {
      final document = documentWithPermission('editor');

      expect(document.isOwner, isFalse);
      expect(document.canEdit, isTrue);
    });

    test('viewer and missing permission cannot edit', () {
      for (final permission in ['viewer', null]) {
        final document = documentWithPermission(permission);

        expect(document.isOwner, isFalse);
        expect(document.canEdit, isFalse);
      }
    });
  });
}
