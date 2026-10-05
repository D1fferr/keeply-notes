import 'package:drift/drift.dart';
import 'tables/folders_table.dart';
import 'tables/notes_table.dart';
import 'tables/reminders_table.dart';
import 'tables/sub_reminders_table.dart';
import 'tables/attachments_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Folders,
    Notes,
    Reminders,
    SubReminders,
    Attachments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // Enable foreign keys support in SQLite
        await customStatement('PRAGMA foreign_keys = ON;');
      },
      onCreate: (m) async {
        await m.createAll();

        // Create performance indices
        await customStatement('CREATE INDEX IF NOT EXISTS idx_folders_parent_id ON folders(parent_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_notes_folder_id ON notes(folder_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_reminders_note_id ON reminders(note_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_sub_reminders_reminder_id ON sub_reminders(reminder_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_attachments_note_id ON attachments(note_id);');
      },
    );
  }
}
