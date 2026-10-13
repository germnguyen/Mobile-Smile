import '../database/app_database.dart';
import '../services/document_service.dart';

class AppDependencies {
  final AppDatabase database;
  final DocumentService documentService;

  AppDependencies({
    required this.database,
    required this.documentService,
  });

  factory AppDependencies.create() {
    final database = AppDatabase();

    final documentService = DocumentService(
      database.documentDao,
    );

    return AppDependencies(
      database: database,
      documentService: documentService,
    );
  }

  Future<void> dispose() async {
    await database.close();
  }
}