import 'package:drift/drift.dart';
import 'folders_table.dart';

@DataClassName('NoteData')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable().references(Folders, #id)();
  TextColumn get title => text()();
  TextColumn get contentJson => text()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
