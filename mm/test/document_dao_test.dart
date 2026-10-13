import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mm/database/app_database.dart';
import 'package:mm/database/daos/document_dao.dart';
import 'package:mm/database/tables.dart';
import 'package:mm/struct/document_type.dart';

void main() {
  late AppDatabase database;
  late DocumentDao dao;

  // ============================================================
  // SETUP
  // ============================================================

  setUp(() {
    database = AppDatabase.forTesting();
    dao = database.documentDao;
  });

  // ============================================================
  // CLEANUP
  // ============================================================

  tearDown(() async {
    await database.close();
  });

  // ============================================================
  // CREATE
  // ============================================================

  test(
    'DAO - thêm tài liệu thành công',
    () async {
      final id = await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Bài giảng Java',
          subject: const drift.Value<String?>(
            'Java',
          ),
          description:
              const drift.Value<String?>(
            'Lập trình hướng đối tượng',
          ),
          documentType:
              const drift.Value<DocumentType>(
            DocumentType.lecture,
          ),
        ),
      );

      expect(id, greaterThan(0));
    },
  );

  // ============================================================
  // READ
  // ============================================================

  test(
    'DAO - lấy tài liệu theo ID',
    () async {
      final id = await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Bài tập Flutter',
          subject: const drift.Value<String?>(
            'Flutter',
          ),
          documentType:
              const drift.Value<DocumentType>(
            DocumentType.assignment,
          ),
        ),
      );

      final document =
          await dao.getDocumentById(id);

      expect(document, isNotNull);
      expect(
        document!.title,
        'Bài tập Flutter',
      );
      expect(
        document.documentType,
        DocumentType.assignment,
      );
    },
  );

  // ============================================================
  // READ ALL
  // ============================================================

  test(
    'DAO - lấy tất cả tài liệu',
    () async {
      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Java',
        ),
      );

      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Flutter',
        ),
      );

      final documents =
          await dao.getAllDocuments();

      expect(documents.length, 2);
    },
  );

  // ============================================================
  // UPDATE
  // ============================================================

  test(
    'DAO - cập nhật tài liệu',
    () async {
      final id = await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Tên cũ',
        ),
      );

      final updated =
          await dao.updateDocument(
        DocumentsCompanion(
          id: drift.Value(id),
          title: const drift.Value(
            'Tên mới',
          ),
        ),
      );

      expect(updated, true);

      final document =
          await dao.getDocumentById(id);

      expect(
        document!.title,
        'Tên mới',
      );
    },
  );

  // ============================================================
  // DELETE
  // ============================================================

  test(
    'DAO - xóa tài liệu',
    () async {
      final id = await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Tài liệu cần xóa',
        ),
      );

      final deleted =
          await dao.deleteDocument(id);

      expect(deleted, 1);

      final document =
          await dao.getDocumentById(id);

      expect(document, isNull);
    },
  );

  // ============================================================
  // SEARCH
  // ============================================================

  test(
    'DAO - tìm kiếm theo từ khóa',
    () async {
      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Lập trình Java',
          subject: const drift.Value<String?>(
            'Java',
          ),
        ),
      );

      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Lập trình Flutter',
          subject: const drift.Value<String?>(
            'Flutter',
          ),
        ),
      );

      final results =
          await dao.searchDocuments(
        keyword: 'Java',
      );

      expect(results.length, 1);
      expect(
        results.first.title,
        'Lập trình Java',
      );
    },
  );

  // ============================================================
  // FILTER
  // ============================================================

  test(
    'DAO - lọc theo loại tài liệu',
    () async {
      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Bài giảng Java',
          documentType:
              const drift.Value<DocumentType>(
            DocumentType.lecture,
          ),
        ),
      );

      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Bài tập Java',
          documentType:
              const drift.Value<DocumentType>(
            DocumentType.assignment,
          ),
        ),
      );

      final results =
          await dao.searchDocuments(
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
  // SEARCH + FILTER
  // ============================================================

  test(
    'DAO - tìm kiếm và lọc kết hợp',
    () async {
      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Java OOP',
          subject: const drift.Value<String?>(
            'Java',
          ),
          documentType:
              const drift.Value<DocumentType>(
            DocumentType.lecture,
          ),
        ),
      );

      await dao.insertDocument(
        DocumentsCompanion.insert(
          title: 'Java Exercise',
          subject: const drift.Value<String?>(
            'Java',
          ),
          documentType:
              const drift.Value<DocumentType>(
            DocumentType.assignment,
          ),
        ),
      );

      final results =
          await dao.searchDocuments(
        keyword: 'Java',
        type: DocumentType.lecture,
      );

      expect(results.length, 1);
      expect(
        results.first.title,
        'Java OOP',
      );
    },
  );
}