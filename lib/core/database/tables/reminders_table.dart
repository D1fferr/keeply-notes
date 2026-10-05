import 'package:drift/drift.dart';
import 'notes_table.dart';

@DataClassName('ReminderData')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().unique().references(Notes, #id)();
  DateTimeColumn get startDateTime => dateTime()();
  TextColumn get repeatType => text()();
  IntColumn get customDaysInterval => integer().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
