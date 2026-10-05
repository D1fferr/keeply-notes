import 'package:drift/drift.dart';

@DataClassName('FolderData')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(Folders, #id)();
  TextColumn get name => text()();
  BoolColumn get isProtected => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
