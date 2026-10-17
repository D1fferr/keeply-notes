import '../../domain/note_entity.dart';

/// Contract for low-level note database operations.
///
/// The implementation delegates directly to [AppDatabase] (Drift).
abstract interface class NoteLocalDataSource {
  // ─── Streams ─────────────────────────────────────────────────────────────

  /// Emits non-deleted notes in [folderId] (or root if null), ordered by
  /// [NoteEntity.isPinned] DESC, then [NoteEntity.updatedAt] DESC.
  Stream<List<NoteEntity>> watchNotesInFolder(String? folderId);

  /// Emits all non-deleted notes across all folders.
  /// When [includeProtected] is `false`, notes inside protected folders or their subfolders are omitted.
  Stream<List<NoteEntity>> watchAllNotes({bool includeProtected = true});

  /// Searches non-deleted notes by title or content.
  /// When [includeProtected] is `false`, notes inside protected folders or their subfolders are omitted.
  Future<List<NoteEntity>> searchNotes(
    String query, {
    bool includeProtected = true,
  });

  // ─── Queries ─────────────────────────────────────────────────────────────

  /// Fetches a single note row by [id]. Returns `null` when absent.
  Future<NoteEntity?> getNoteById(String id);

  // ─── Mutations ───────────────────────────────────────────────────────────

  /// Inserts a new note row and returns the resulting entity.
  Future<NoteEntity> insertNote({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    required bool isPinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  /// Updates fields of an existing note.
  Future<NoteEntity> updateNote({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    bool? isPinned,
    required DateTime updatedAt,
  });

  /// Toggles the [isPinned] status of the note.
  Future<NoteEntity> togglePin(String id, DateTime updatedAt);

  /// Moves the note to [newFolderId] (or root if null).
  Future<NoteEntity> updateNoteFolder(
    String id,
    String? newFolderId,
    DateTime updatedAt,
  );

  /// Soft-deletes the note (sets isDeleted = true).
  Future<void> softDeleteNote(String id, DateTime updatedAt);
}
