import 'package:drift/drift.dart';
import 'reminders_table.dart';

@DataClassName('SubReminderData')
class SubReminders extends Table {
  TextColumn get id => text()();
  TextColumn get reminderId => text().references(Reminders, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  IntColumn get offsetMinutes => integer().nullable()();
  TextColumn get exactTime => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
