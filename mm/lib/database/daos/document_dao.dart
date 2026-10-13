import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import '../../struct/document_type.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(AppDatabase db) : super(db);

  // ============================================================
  // CREATE
  // ============================================================

  Future<int> insertDocument(
    DocumentsCompanion document,
  ) {
    return into(documents).insert(document);
  }

  // ============================================================
  // READ ALL
  // ============================================================

  Future<List<Document>> getAllDocuments() {
    return (select(documents)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  // ============================================================
  // READ BY ID
  // ============================================================

  Future<Document?> getDocumentById(int id) {
    return (select(documents)
          ..where(
            (tbl) => tbl.id.equals(id),
          ))
        .getSingleOrNull();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> updateDocument(
    DocumentsCompanion document,
  ) async {
    final rowsUpdated =
        await update(documents).write(document);

    return rowsUpdated > 0;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<int> deleteDocument(int id) {
    return (delete(documents)
          ..where(
            (tbl) => tbl.id.equals(id),
          ))
        .go();
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  Future<List<Document>> searchDocuments({
  String? keyword,
  DocumentType? type,
}) {
  final query = select(documents);

  query.where((tbl) {
    Expression<bool>? condition;

    if (keyword != null &&
        keyword.trim().isNotEmpty) {
      final searchKeyword = keyword.trim();

      condition =
          tbl.title.contains(searchKeyword) |
          tbl.description.contains(searchKeyword) |
          tbl.subject.contains(searchKeyword);
    }

    if (type != null) {
      final typeCondition =
          tbl.documentType.equals(type.index);

      if (condition == null) {
        condition = typeCondition;
      } else {
        condition =
            condition & typeCondition;
      }
    }

    return condition ?? const Constant(true);
  });

  query.orderBy([
    (tbl) => OrderingTerm(
          expression: tbl.createdAt,
          mode: OrderingMode.desc,
        ),
  ]);

  return query.get();
}

  // ============================================================
  // FILTER BY TYPE
  // ============================================================

  Future<List<Document>> getDocumentsByType(
    DocumentType type,
  ) {
    return (select(documents)
          ..where(
            (tbl) =>
                tbl.documentType.equals(type.index),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }
}