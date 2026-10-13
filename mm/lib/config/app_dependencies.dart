import '../database/app_database.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';

class AppDependencies {
  final AppDatabase database;
  final AuthService authService;
  final DocumentService documentService;

  AppDependencies({
    required this.database,
    required this.authService,
    required this.documentService,
  });

  factory AppDependencies.create() {
    final database = AppDatabase();
    final authService = AuthService();

    final documentService = DocumentService(
      database.documentDao,
    );

    return AppDependencies(
      database: database,
      authService: authService,
      documentService: documentService,
    );
  }

  Future<void> dispose() async {
    await database.close();
  }
}