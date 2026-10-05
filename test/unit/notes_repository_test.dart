import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/database/app_database.dart';
import 'package:keeply_notes/features/notes/data/datasources/note_local_data_source_impl.dart';
import 'package:keeply_notes/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  group('NoteRepository & NoteLocalDataSource Unit Tests', () {
    late AppDatabase db;
    late NoteLocalDataSourceImpl dataSource;
    late NoteRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dataSource = NoteLocalDataSourceImpl(db);
      repository = NoteRepositoryImpl(dataSource);
    });

    tearDown(() async {
      await db.close();
    });

    test('createNote persists note with Delta JSON content and returns entity', () async {
      const deltaJson = '[{"insert":"Sample note content\\n"}]';
      final note = await repository.createNote(
        title: 'Project Roadmap',
        contentJson: deltaJson,
        isPinned: false,
      );

      expect(note.id, isNotEmpty);
      expect(note.title, equals('Project Roadmap'));
      expect(note.contentJson, equals(deltaJson));
      expect(note.isPinned, isFalse);
      expect(note.isDeleted, isFalse);
      expect(note.folderId, isNull);

      final fetched = await repository.getNoteById(note.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Project Roadmap'));
    });

    test('watchNotesInFolder separates root notes from folder notes', () async {
      const folderId = 'folder-123';

      // Insert root note
      await repository.createNote(
        title: 'Root Note',
        contentJson: '[]',
      );

      // Insert folder note
      await repository.createNote(
        folderId: folderId,
        title: 'Folder Note',
        contentJson: '[]',
      );

      // Watch root
      final rootNotes = await repository.watchNotesInFolder(null).first;
      expect(rootNotes.length, equals(1));
      expect(rootNotes.first.title, equals('Root Note'));

      // Watch folder
      final folderNotes = await repository.watchNotesInFolder(folderId).first;
      expect(folderNotes.length, equals(1));
      expect(folderNotes.first.title, equals('Folder Note'));
    });

    test('notes are ordered by isPinned DESC, then updatedAt DESC', () async {
      final note1 = await repository.createNote(
        title: 'Regular Note 1',
        contentJson: '[]',
        isPinned: false,
      );

      // Delay slightly to ensure distinct timestamps
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final note2 = await repository.createNote(
        title: 'Regular Note 2',
        contentJson: '[]',
        isPinned: false,
      );

      // Pin note1
      await repository.togglePin(note1.id);

      final notes = await repository.watchNotesInFolder(null).first;
      expect(notes.length, equals(2));
      // Pinned note1 should be first even though note2 was created later
      expect(notes.first.id, equals(note1.id));
      expect(notes.first.isPinned, isTrue);
      expect(notes.last.id, equals(note2.id));
    });

    test('updateNote updates title, contentJson, and timestamps', () async {
      final note = await repository.createNote(
        title: 'Original Title',
        contentJson: '[{"insert":"Original"}]',
      );

      final updated = await repository.updateNote(
        id: note.id,
        title: 'Updated Title',
        contentJson: '[{"insert":"Updated"}]',
        isPinned: true,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.contentJson, equals('[{"insert":"Updated"}]'));
      expect(updated.isPinned, isTrue);
      expect(updated.updatedAt.isAfter(note.createdAt) ||
          updated.updatedAt.isAtSameMomentAs(note.createdAt), isTrue);

      final fetched = await repository.getNoteById(note.id);
      expect(fetched!.title, equals('Updated Title'));
      expect(fetched.isPinned, isTrue);
    });

    test('moveNote changes folderId', () async {
      final note = await repository.createNote(
        title: 'Note to move',
        contentJson: '[]',
      );
      expect(note.folderId, isNull);

      final moved = await repository.moveNote(note.id, 'folder-xyz');
      expect(moved.folderId, equals('folder-xyz'));

      final fetched = await repository.getNoteById(note.id);
      expect(fetched!.folderId, equals('folder-xyz'));
    });

    test('deleteNote soft-deletes note and excludes it from watch streams', () async {
      final note = await repository.createNote(
        title: 'Note to delete',
        contentJson: '[]',
      );

      var notes = await repository.watchNotesInFolder(null).first;
      expect(notes.length, equals(1));

      await repository.deleteNote(note.id);

      // Verify excluded from active stream
      notes = await repository.watchNotesInFolder(null).first;
      expect(notes, isEmpty);

      // Verify row still exists in DB but with isDeleted = true
      final rawRow = await (db.select(db.notes)..where((n) => n.id.equals(note.id)))
          .getSingle();
      expect(rawRow.isDeleted, isTrue);
    });
  });
}
