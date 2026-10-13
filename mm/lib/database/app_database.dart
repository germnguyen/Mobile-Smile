import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mm/struct/document_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/document_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Documents,
  ],
  daos: [
    DocumentDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting()
    : super(
        NativeDatabase.memory(),
      );
      
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final file = File(
      p.join(
        directory.path,
        'study_cashew.sqlite',
      ),
    );

    return NativeDatabase.createInBackground(file);
  });
}