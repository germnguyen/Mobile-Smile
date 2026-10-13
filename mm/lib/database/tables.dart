import 'package:drift/drift.dart';

import '../struct/document_type.dart';


class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(
        min: 1,
        max: 250,
      )();

  TextColumn get description => text().nullable()();

  TextColumn get filePath => text().nullable()();

  IntColumn get documentType =>
      intEnum<DocumentType>().withDefault(
        Constant(DocumentType.other.index),
      )();

  TextColumn get subject => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();
}