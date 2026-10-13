import 'package:drift/drift.dart';
import 'package:mm/database/app_database.dart';

import '../database/daos/document_dao.dart';
import '../struct/document_type.dart';

class DocumentService {
  final DocumentDao _documentDao;

  DocumentService(this._documentDao);

  // =========================================================
  // CREATE
  // =========================================================

  Future<int> addDocument({
    required String title,
    String? description,
    String? filePath,
    DocumentType documentType = DocumentType.other,
    String? subject,
  }) async {
    // Chuẩn hóa title
    final normalizedTitle = title.trim();

    // Kiểm tra title không được rỗng
    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'Tên tài liệu không được để trống.',
      );
    }

    // Kiểm tra độ dài
    if (normalizedTitle.length > 250) {
      throw ArgumentError(
        'Tên tài liệu không được vượt quá 250 ký tự.',
      );
    }

    final id = await _documentDao.insertDocument(
      DocumentsCompanion.insert(
        title: normalizedTitle,
        description: Value(
          _normalizeNullableText(description),
        ),
        filePath: Value(
          _normalizeNullableText(filePath),
        ),
        documentType: Value(documentType),
        subject: Value(
          _normalizeNullableText(subject),
        ),
      ),
    );

    return id;
  }

  // =========================================================
  // READ ALL
  // =========================================================

  Future<List<Document>> getAllDocuments() {
    return _documentDao.getAllDocuments();
  }

  // =========================================================
  // READ BY ID
  // =========================================================

  Future<Document?> getDocumentById(int id) {
    return _documentDao.getDocumentById(id);
  }

  // =========================================================
  // UPDATE
  // =========================================================

  Future<bool> updateDocument({
    required int id,
    required String title,
    String? description,
    String? filePath,
    DocumentType? documentType,
    String? subject,
  }) async {
    // Chuẩn hóa title
    final normalizedTitle = title.trim();

    // Validation
    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'Tên tài liệu không được để trống.',
      );
    }

    if (normalizedTitle.length > 250) {
      throw ArgumentError(
        'Tên tài liệu không được vượt quá 250 ký tự.',
      );
    }

    // Kiểm tra document có tồn tại không
    final existingDocument =
        await _documentDao.getDocumentById(id);

    if (existingDocument == null) {
      return false;
    }

    final updated = await _documentDao.updateDocument(
      DocumentsCompanion(
        id: Value(id),
        title: Value(normalizedTitle),
        description: Value(
          _normalizeNullableText(description),
        ),
        filePath: Value(
          _normalizeNullableText(filePath),
        ),
        subject: Value(
          _normalizeNullableText(subject),
        ),
        documentType: documentType == null
            ? const Value.absent()
            : Value(documentType),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return updated;
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<bool> deleteDocument(int id) async {
    final deletedRows =
        await _documentDao.deleteDocument(id);

    return deletedRows > 0;
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<Document>> searchDocuments({
  String? keyword,
  DocumentType? type,
  }) async {
    final normalizedKeyword =
        keyword?.trim();

    return _documentDao.searchDocuments(
      keyword: normalizedKeyword,
      type: type,
    );
  }

  // =========================================================
  // FILTER BY TYPE
  // =========================================================

  Future<List<Document>> getDocumentsByType(
    DocumentType type,
  ) {
    return _documentDao.getDocumentsByType(type);
  }

  // =========================================================
  // HELPER
  // =========================================================

  String? _normalizeNullableText(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}