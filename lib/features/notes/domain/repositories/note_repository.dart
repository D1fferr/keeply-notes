import '../note_entity.dart';

/// Abstract contract for note data operations.
///
/// Defines CRUD operations, real-time reactive streams, pinning,
/// moving between folders, and soft deletion.
abstract interface class NoteRepository {
  // ─── Read ────────────────────────────────────────────────────────────────

  /// Returns a real-time stream of all non-deleted notes in a specific folder.
  ///
  /// Pass `null` for [folderId] to retrieve root-level notes (not in any folder).
  /// Results are sorted by [NoteEntity.isPinned] descending, then [NoteEntity.updatedAt] descending.
  Stream<List<NoteEntity>> watchNotesInFolder(String? folderId);

  /// Returns a real-time stream of all non-deleted notes across all folders.
  Stream<List<NoteEntity>> watchAllNotes();

  /// Fetches a single note by its [id]. Returns `null` when not found.
  Future<NoteEntity?> getNoteById(String id);

  // ─── Write ───────────────────────────────────────────────────────────────

  /// Creates a new note and returns the persisted entity.
  Future<NoteEntity> createNote({
    String? folderId,
    required String title,
    required String contentJson,
    bool isPinned = false,
  });

  /// Updates the note identified by [id].
  Future<NoteEntity> updateNote({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    bool? isPinned,
  });

  /// Toggles the pinned status of a note.
  Future<NoteEntity> togglePin(String id);

  /// Moves a note to a different folder (or to root level when [newFolderId] is null).
  Future<NoteEntity> moveNote(String id, String? newFolderId);

  /// Soft-deletes a note by setting [NoteEntity.isDeleted] to `true`.
  Future<void> deleteNote(String id);
}
