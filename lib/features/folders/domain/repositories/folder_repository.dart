import '../folder_entity.dart';
import '../../../notes/domain/note_entity.dart';

/// Abstract contract for folder data operations.
///
/// Defines CRUD operations and the recursive subtree query used to
/// retrieve all subfolders and notes within a folder hierarchy.
abstract interface class FolderRepository {
  // ─── Read ────────────────────────────────────────────────────────────────

  /// Returns a real-time stream of all non-deleted root-level folders
  /// (i.e. folders whose [FolderEntity.parentId] is `null`).
  Stream<List<FolderEntity>> watchRootFolders();

  /// Returns a real-time stream of all non-deleted direct children of [parentId].
  Stream<List<FolderEntity>> watchSubfolders(String parentId);

  /// Returns a real-time stream of all folders (including the folder itself)
  /// that are within the subtree rooted at [folderId].
  ///
  /// Uses a recursive SQLite Common Table Expression (CTE) internally.
  Stream<List<FolderEntity>> watchFolderSubtree(String folderId);

  /// Fetches a single folder by its [id]. Returns `null` when not found.
  Future<FolderEntity?> getFolderById(String id);

  /// Returns all non-deleted notes that belong to the subtree rooted at
  /// [folderId] (including the folder itself and all its descendants).
  ///
  /// Executes the recursive CTE:
  /// ```sql
  /// WITH RECURSIVE SubFolders AS (
  ///   SELECT id FROM folders WHERE id = :folderId
  ///   UNION ALL
  ///   SELECT f.id FROM folders f
  ///   INNER JOIN SubFolders sf ON f.parent_id = sf.id
  /// )
  /// SELECT * FROM notes
  /// WHERE folder_id IN (SELECT id FROM SubFolders) AND is_deleted = 0;
  /// ```
  Future<List<NoteEntity>> getNotesInSubtree(String folderId);

  // ─── Write ───────────────────────────────────────────────────────────────

  /// Creates a new folder and returns the persisted entity.
  Future<FolderEntity> createFolder({
    required String name,
    String? parentId,
    bool isProtected = false,
  });

  /// Renames the folder identified by [id].
  Future<FolderEntity> renameFolder(String id, String newName);

  /// Moves a folder to a new parent.
  ///
  /// Pass `null` for [newParentId] to move the folder to root level.
  /// Throws [ArgumentError] if moving [id] under one of its own descendants
  /// (which would create a cycle).
  Future<FolderEntity> moveFolder(String id, {String? newParentId});

  /// Toggles the biometric-protection flag on a folder.
  Future<FolderEntity> setFolderProtection(String id, {required bool isProtected});

  /// Soft-deletes a folder and all its descendants by setting [isDeleted] to
  /// `true`. Associated notes are NOT deleted — they remain in the database
  /// but become unreachable through the folder tree.
  Future<void> deleteFolder(String id);
}
