import 'package:flutter_test/flutter_test.dart';
import 'package:mm/database/app_database.dart';
import 'package:mm/services/document_service.dart';
import 'package:mm/struct/document_type.dart';

void main() {
  late AppDatabase database;
  late DocumentService service;

  // ============================================================
  // SETUP
  // ============================================================

  setUp(() {
    database = AppDatabase.forTesting();

    service = DocumentService(
      database.documentDao,
    );
  });

  // ============================================================
  // CLEANUP
  // ============================================================

  tearDown(() async {
    await database.close();
  });

  // ============================================================
  // ADD VALID DOCUMENT
  // ============================================================

  test(
    'Service - thêm tài liệu hợp lệ',
    () async {
      final id =
          await service.addDocument(
        title: 'Bài giảng Java',
        subject: 'Java',
        description:
            'Lập trình hướng đối tượng',
        documentType:
            DocumentType.lecture,
      );

      expect(id, greaterThan(0));
    },
  );

  // ============================================================
  // VALIDATE EMPTY TITLE
  // ============================================================

  test(
    'Service - không cho phép tên tài liệu rỗng',
    () async {
      expect(
        () => service.addDocument(
          title: '   ',
        ),
        throwsArgumentError,
      );
    },
  );

  // ============================================================
  // VALIDATE TITLE LENGTH
  // ============================================================

  test(
    'Service - không cho phép tên tài liệu vượt quá 250 ký tự',
    () async {
      final longTitle =
          'A' * 251;

      expect(
        () => service.addDocument(
          title: longTitle,
        ),
        throwsArgumentError,
      );
    },
  );

  // ============================================================
  // NORMALIZE TITLE
  // ============================================================

  test(
    'Service - loại bỏ khoảng trắng thừa ở tên tài liệu',
    () async {
      final id =
          await service.addDocument(
        title: '   Java OOP   ',
      );

      final document =
          await service.getDocumentById(id);

      expect(
        document!.title,
        'Java OOP',
      );
    },
  );

  // ============================================================
  // NORMALIZE OPTIONAL TEXT
  // ============================================================

  test(
    'Service - chuyển chuỗi rỗng thành null',
    () async {
      final id =
          await service.addDocument(
        title: 'Java',
        subject: '   ',
        description: '   ',
      );

      final document =
          await service.getDocumentById(id);

      expect(
        document!.subject,
        isNull,
      );

      expect(
        document.description,
        isNull,
      );
    },
  );

  // ============================================================
  // SEARCH
  // ============================================================

  test(
    'Service - tìm kiếm tài liệu',
    () async {
      await service.addDocument(
        title: 'Java OOP',
        subject: 'Java',
      );

      await service.addDocument(
        title: 'Flutter cơ bản',
        subject: 'Flutter',
      );

      final results =
          await service.searchDocuments(
        keyword: 'Java',
      );

      expect(results.length, 1);
      expect(
        results.first.title,
        'Java OOP',
      );
    },
  );

  // ============================================================
  // FILTER
  // ============================================================

  test(
    'Service - lọc tài liệu theo loại',
    () async {
      await service.addDocument(
        title: 'Bài giảng Java',
        documentType:
            DocumentType.lecture,
      );

      await service.addDocument(
        title: 'Bài tập Java',
        documentType:
            DocumentType.assignment,
      );

      final results =
          await service.searchDocuments(
        type: DocumentType.lecture,
      );

      expect(results.length, 1);
      expect(
        results.first.documentType,
        DocumentType.lecture,
      );
    },
  );

  // ============================================================
  // DELETE
  // ============================================================

  test(
    'Service - xóa tài liệu',
    () async {
      final id =
          await service.addDocument(
        title: 'Tài liệu cần xóa',
      );

      final deleted =
          await service.deleteDocument(id);

      expect(deleted, true);

      final document =
          await service.getDocumentById(id);

      expect(document, isNull);
    },
  );

  // ============================================================
  // DELETE NOT EXISTING
  // ============================================================

  test(
    'Service - xóa tài liệu không tồn tại',
    () async {
      final deleted =
          await service.deleteDocument(
        9999,
      );

      expect(deleted, false);
    },
  );
}