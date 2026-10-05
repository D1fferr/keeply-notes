import 'package:uuid/uuid.dart';
import '../../domain/folder_entity.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../../notes/domain/note_entity.dart';
import '../datasources/folder_local_data_source.dart';

/// Implementation of [FolderRepository] that delegates to
/// [FolderLocalDataSource] and enforces business rules such as
/// cycle detection on folder moves.
class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl(this._dataSource) : _uuid = const Uuid();

  final FolderLocalDataSource _dataSource;
  final Uuid _uuid;

  // ─── Read ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<FolderEntity>> watchRootFolders() =>
      _dataSource.watchRootFolders();

  @override
  Stream<List<FolderEntity>> watchSubfolders(String parentId) =>
      _dataSource.watchSubfolders(parentId);

  @override
  Stream<List<FolderEntity>> watchFolderSubtree(String folderId) =>
      _dataSource.watchFolderSubtree(folderId);

  @override
  Future<FolderEntity?> getFolderById(String id) =>
      _dataSource.getFolderById(id);

  @override
  Future<List<NoteEntity>> getNotesInSubtree(String folderId) =>
      _dataSource.getNotesInSubtree(folderId);

  // ─── Write ────────────────────────────────────────────────────────────────

  @override
  Future<FolderEntity> createFolder({
    required String name,
    String? parentId,
    bool isProtected = false,
  }) {
    final now = DateTime.now().toUtc();
    return _dataSource.insertFolder(
      id: _uuid.v4(),
      name: name.trim(),
      parentId: parentId,
      isProtected: isProtected,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<FolderEntity> renameFolder(String id, String newName) =>
      _dataSource.updateFolderName(
          id, newName.trim(), DateTime.now().toUtc());

  @override
  Future<FolderEntity> moveFolder(String id, {String? newParentId}) async {
    // Guard: moving a folder into one of its own descendants creates a cycle.
    if (newParentId != null) {
      final subtreeIds = await _dataSource.getSubtreeIds(id);
      if (subtreeIds.contains(newParentId)) {
        throw ArgumentError(
          'Cannot move folder "$id" into "$newParentId": '
          'target is a descendant of the source folder.',
        );
      }
    }
    return _dataSource.updateFolderParent(
        id, newParentId, DateTime.now().toUtc());
  }

  @override
  Future<FolderEntity> setFolderProtection(
    String id, {
    required bool isProtected,
  }) =>
      _dataSource.updateFolderProtection(
          id, isProtected, DateTime.now().toUtc());

  @override
  Future<void> deleteFolder(String id) =>
      _dataSource.softDeleteFolderSubtree(id);
}
