import '../folder_entity.dart';
import '../repositories/folder_repository.dart';

/// Creates a new folder, optionally nested under [parentId].
class CreateFolderUseCase {
  const CreateFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<FolderEntity> call({
    required String name,
    String? parentId,
    bool isProtected = false,
  }) =>
      _repository.createFolder(
        name: name,
        parentId: parentId,
        isProtected: isProtected,
      );
}

/// Renames a folder.
class RenameFolderUseCase {
  const RenameFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<FolderEntity> call(String id, String newName) =>
      _repository.renameFolder(id, newName);
}

/// Moves a folder to a new parent (or to root level when [newParentId] is null).
///
/// Throws [ArgumentError] if the move would create a cycle in the hierarchy.
class MoveFolderUseCase {
  const MoveFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<FolderEntity> call(String id, {String? newParentId}) =>
      _repository.moveFolder(id, newParentId: newParentId);
}

/// Toggles biometric protection on a folder.
class SetFolderProtectionUseCase {
  const SetFolderProtectionUseCase(this._repository);

  final FolderRepository _repository;

  Future<FolderEntity> call(String id, {required bool isProtected}) =>
      _repository.setFolderProtection(id, isProtected: isProtected);
}

/// Soft-deletes a folder and its entire descendant subtree.
class DeleteFolderUseCase {
  const DeleteFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<void> call(String id) => _repository.deleteFolder(id);
}
