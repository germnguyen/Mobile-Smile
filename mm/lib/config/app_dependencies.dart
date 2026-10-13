import '../database/app_database.dart';
import '../services/auth_service.dart';
import '../services/cloud_document_service.dart';
import '../services/document_service.dart';

class AppDependencies {
  final AppDatabase database;
  final AuthService authService;
  final DocumentService documentService;
  final CloudDocumentService cloudDocumentService;

  AppDependencies({
    required this.database,
    required this.authService,
    required this.documentService,
    required this.cloudDocumentService,
  });

  factory AppDependencies.create() {
    final database = AppDatabase();
    final authService = AuthService();

    final documentService = DocumentService(
      database.documentDao,
    );
    final cloudDocumentService = CloudDocumentService();

    return AppDependencies(
      database: database,
      authService: authService,
      documentService: documentService,
      cloudDocumentService: cloudDocumentService,
    );
  }

  Future<void> dispose() async {
    await database.close();
  }
}