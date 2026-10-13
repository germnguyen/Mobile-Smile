import 'package:flutter_test/flutter_test.dart';
import 'package:mm/database/app_database.dart';
import 'package:mm/struct/document_type.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('Database can be initialized', () async {
    expect(database, isNotNull);
  });
}