import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/features/notes/domain/note_entity.dart';
import 'package:keeply_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:keeply_notes/features/notes/domain/usecases/note_crud_usecases.dart';
import 'package:keeply_notes/features/notes/presentation/delegates/note_search_delegate.dart';
import 'package:keeply_notes/features/notes/presentation/delegates/note_search_filter.dart';
import 'package:keeply_notes/features/reminders/domain/reminder_entity.dart';
import 'package:keeply_notes/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:keeply_notes/features/reminders/domain/usecases/reminder_usecases.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository(this.notes);
  final List<NoteEntity> notes;

  @override
  Future<List<NoteEntity>> searchNotes(String query, {bool includeProtected = true}) async {
    final lower = query.toLowerCase();
    return notes.where((n) {
      if (!includeProtected && n.folderId == 'protected_folder') return false;
      return n.title.toLowerCase().contains(lower) ||
          n.contentJson.toLowerCase().contains(lower);
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository(this.activeReminders);
  final List<ReminderEntity> activeReminders;

  @override
  Future<List<ReminderEntity>> getAllActiveReminders() async {
    return activeReminders;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();

  final note1 = NoteEntity(
    id: 'note-1',
    folderId: null,
    title: 'Meeting Notes',
    contentJson: '[{"insert":"Discuss project timeline\\n"}]',
    isPinned: true,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final note2 = NoteEntity(
    id: 'note-2',
    folderId: null,
    title: 'Shopping List',
    contentJson: '[{"insert":"Buy milk and eggs\\n"}]',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final note3 = NoteEntity(
    id: 'note-3',
    folderId: 'protected_folder',
    title: 'Secret Passwords',
    contentJson: '[{"insert":"Very confidential\\n"}]',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final allNotes = [note1, note2, note3];

  final reminder1 = ReminderEntity(
    id: 'rem-1',
    noteId: 'note-2',
    startDateTime: now.add(const Duration(hours: 2)),
    repeatType: RepeatType.none,
    isEnabled: true,
  );

  group('NoteSearchDelegate filtering logic', () {
    late FakeNoteRepository noteRepo;
    late FakeReminderRepository reminderRepo;
    late SearchNotesUseCase searchNotesUseCase;
    late GetAllActiveRemindersUseCase getAllActiveRemindersUseCase;

    setUp(() {
      noteRepo = FakeNoteRepository(allNotes);
      reminderRepo = FakeReminderRepository([reminder1]);
      searchNotesUseCase = SearchNotesUseCase(noteRepo);
      getAllActiveRemindersUseCase = GetAllActiveRemindersUseCase(reminderRepo);
    });

    test('searches notes across titles and content', () async {
      final results = await searchNotesUseCase('milk');
      expect(results.length, 1);
      expect(results.first.id, 'note-2');

      final titleResults = await searchNotesUseCase('Meeting');
      expect(titleResults.length, 1);
      expect(titleResults.first.id, 'note-1');
    });

    test('excludes protected notes when includeProtected is false', () async {
      final resultsProtected = await searchNotesUseCase('Secret', includeProtected: false);
      expect(resultsProtected, isEmpty);

      final resultsUnlocked = await searchNotesUseCase('Secret', includeProtected: true);
      expect(resultsUnlocked.length, 1);
      expect(resultsUnlocked.first.id, 'note-3');
    });

    test('delegates properly configure and initialize', () {
      final delegate = NoteSearchDelegate(
        searchNotesUseCase: searchNotesUseCase,
        getAllActiveRemindersUseCase: getAllActiveRemindersUseCase,
        onNoteSelected: (_) {},
      );

      expect(delegate.searchFieldLabel, 'Search notes...');
      expect(NoteSearchFilter.values.length, 3);
      expect(NoteSearchFilter.values, contains(NoteSearchFilter.pinned));
      expect(NoteSearchFilter.values, contains(NoteSearchFilter.hasReminders));
    });
  });
}
