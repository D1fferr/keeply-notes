import '../note_entity.dart';
import '../repositories/note_repository.dart';

/// Watches all non-deleted notes in a specific folder (or root if null).
class WatchNotesInFolderUseCase {
  const WatchNotesInFolderUseCase(this._repository);

  final NoteRepository _repository;

  Stream<List<NoteEntity>> call(String? folderId) =>
      _repository.watchNotesInFolder(folderId);
}

/// Watches all non-deleted notes across all folders.
class WatchAllNotesUseCase {
  const WatchAllNotesUseCase(this._repository);

  final NoteRepository _repository;

  Stream<List<NoteEntity>> call() => _repository.watchAllNotes();
}

/// Fetches a single note by its ID.
class GetNoteByIdUseCase {
  const GetNoteByIdUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity?> call(String id) => _repository.getNoteById(id);
}

/// Creates a new note.
class CreateNoteUseCase {
  const CreateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity> call({
    String? folderId,
    required String title,
    required String contentJson,
    bool isPinned = false,
  }) =>
      _repository.createNote(
        folderId: folderId,
        title: title,
        contentJson: contentJson,
        isPinned: isPinned,
      );
}

/// Updates an existing note.
class UpdateNoteUseCase {
  const UpdateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity> call({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    bool? isPinned,
  }) =>
      _repository.updateNote(
        id: id,
        folderId: folderId,
        title: title,
        contentJson: contentJson,
        isPinned: isPinned,
      );
}

/// Toggles the pinned status of a note.
class TogglePinNoteUseCase {
  const TogglePinNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity> call(String id) => _repository.togglePin(id);
}

/// Moves a note to another folder (or root).
class MoveNoteUseCase {
  const MoveNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity> call(String id, String? newFolderId) =>
      _repository.moveNote(id, newFolderId);
}

/// Soft-deletes a note.
class DeleteNoteUseCase {
  const DeleteNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.deleteNote(id);
}
