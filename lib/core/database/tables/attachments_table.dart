import 'package:drift/drift.dart';
import 'notes_table.dart';

@DataClassName('AttachmentData')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(Notes, #id)();
  TextColumn get localPath => text()();
  IntColumn get fileSize => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
