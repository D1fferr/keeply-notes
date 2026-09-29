import '../../../notes/domain/note_entity.dart';
import '../repositories/folder_repository.dart';

/// Returns all non-deleted notes that reside within the subtree rooted at
/// [folderId] (including the folder itself and all its descendants).
///
/// Internally executes the recursive SQLite CTE defined in [FolderRepository].
class GetNotesInSubtreeUseCase {
  const GetNotesInSubtreeUseCase(this._repository);

  final FolderRepository _repository;

  Future<List<NoteEntity>> call(String folderId) =>
      _repository.getNotesInSubtree(folderId);
}
