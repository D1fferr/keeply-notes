import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/database/app_database.dart';

void main() {
  group('Encrypted Database & Drift Tables Unit Tests', () {
    late AppDatabase db;

    setUp(() {
      // In-memory executor for unit testing
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Verify all tables and foreign keys are created successfully', () async {
      final tables = db.allTables;
      expect(tables.length, equals(5));

      final tableNames = tables.map((t) => t.actualTableName).toList();
      expect(tableNames, contains('folders'));
      expect(tableNames, contains('notes'));
      expect(tableNames, contains('reminders'));
      expect(tableNames, contains('sub_reminders'));
      expect(tableNames, contains('attachments'));
    });

    test('Verify folder insert and retrieval', () async {
      final now = DateTime.now();
      const folderId = 'folder-1';
      
      await db.into(db.folders).insert(
        FolderData(
          id: folderId,
          name: 'Personal Notes',
          isProtected: false,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      );

      final folders = await db.select(db.folders).get();
      expect(folders.length, equals(1));
      expect(folders.first.id, equals(folderId));
      expect(folders.first.name, equals('Personal Notes'));
    });

    test('Verify sub-reminder cascade delete when primary reminder is deleted', () async {
      final now = DateTime.now();
      const noteId = 'note-1';
      const reminderId = 'reminder-1';
      const subReminderId = 'sub-1';

      // Insert Note
      await db.into(db.notes).insert(
        NoteData(
          id: noteId,
          title: 'Meeting Notes',
          contentJson: '[]',
          isPinned: false,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      );

      // Insert Reminder
      await db.into(db.reminders).insert(
        ReminderData(
          id: reminderId,
          noteId: noteId,
          startDateTime: now,
          repeatType: 'daily',
          isEnabled: true,
        ),
      );

      // Insert SubReminder
      await db.into(db.subReminders).insert(
        const SubReminderData(
          id: subReminderId,
          reminderId: reminderId,
          type: 'offsetMinutes',
          offsetMinutes: 15,
        ),
      );

      var subRemindersList = await db.select(db.subReminders).get();
      expect(subRemindersList.length, equals(1));

      // Delete Reminder
      await (db.delete(db.reminders)..where((tbl) => tbl.id.equals(reminderId))).go();

      // Verify SubReminder is cascadingly deleted
      subRemindersList = await db.select(db.subReminders).get();
      expect(subRemindersList, isEmpty);
    });
  });
}
