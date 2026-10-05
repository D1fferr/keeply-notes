import '../../domain/folder_entity.dart';
import '../../../../notes/domain/note_entity.dart';

/// Contract for low-level folder database operations.
///
/// The implementation delegates directly to [AppDatabase] (Drift).
abstract interface class FolderLocalDataSource {
  // ─── Streams ─────────────────────────────────────────────────────────────

  /// Emits root-level folders (parentId IS NULL, isDeleted = false) on
  /// every database change.
  Stream<List<FolderEntity>> watchRootFolders();

  /// Emits direct children of [parentId] (isDeleted = false) on every
  /// database change.
  Stream<List<FolderEntity>> watchSubfolders(String parentId);

  /// Emits all folders within the subtree rooted at [folderId] using a
  /// recursive CTE. Includes the folder itself.
  Stream<List<FolderEntity>> watchFolderSubtree(String folderId);

  // ─── Queries ─────────────────────────────────────────────────────────────

  /// Fetches a single folder row by [id]. Returns `null` when absent.
  Future<FolderEntity?> getFolderById(String id);

  /// Runs the recursive CTE and returns all non-deleted notes whose
  /// [folderId] falls within the subtree rooted at [folderId].
  Future<List<NoteEntity>> getNotesInSubtree(String folderId);

  /// Returns the set of all folder IDs in the subtree rooted at [folderId].
  ///
  /// Used internally for cycle detection before [moveFolder].
  Future<Set<String>> getSubtreeIds(String folderId);

  // ─── Mutations ───────────────────────────────────────────────────────────

  /// Inserts a new folder row and returns the resulting entity.
  Future<FolderEntity> insertFolder({
    required String id,
    required String name,
    String? parentId,
    required bool isProtected,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  /// Updates [name] of the folder row with the given [id]. Returns the
  /// updated entity.
  Future<FolderEntity> updateFolderName(
      String id, String newName, DateTime updatedAt);

  /// Updates [parentId] of the folder row with the given [id]. Returns the
  /// updated entity.
  Future<FolderEntity> updateFolderParent(
      String id, String? newParentId, DateTime updatedAt);

  /// Updates [isProtected] of the folder row with the given [id]. Returns
  /// the updated entity.
  Future<FolderEntity> updateFolderProtection(
      String id, bool isProtected, DateTime updatedAt);

  /// Soft-deletes the folder and all its descendants (sets isDeleted = true).
  Future<void> softDeleteFolderSubtree(String folderId);
}
