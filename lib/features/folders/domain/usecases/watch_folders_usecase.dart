import '../folder_entity.dart';
import '../repositories/folder_repository.dart';

/// Watches the stream of root-level (top-level) folders.
class WatchRootFoldersUseCase {
  const WatchRootFoldersUseCase(this._repository);

  final FolderRepository _repository;

  Stream<List<FolderEntity>> call() => _repository.watchRootFolders();
}

/// Watches the stream of direct children of a given parent folder.
class WatchSubfoldersUseCase {
  const WatchSubfoldersUseCase(this._repository);

  final FolderRepository _repository;

  Stream<List<FolderEntity>> call(String parentId) =>
      _repository.watchSubfolders(parentId);
}

/// Watches the full subtree of folders rooted at [folderId].
class WatchFolderSubtreeUseCase {
  const WatchFolderSubtreeUseCase(this._repository);

  final FolderRepository _repository;

  Stream<List<FolderEntity>> call(String folderId) =>
      _repository.watchFolderSubtree(folderId);
}

/// Fetches a single folder by ID.
class GetFolderByIdUseCase {
  const GetFolderByIdUseCase(this._repository);

  final FolderRepository _repository;

  Future<FolderEntity?> call(String id) => _repository.getFolderById(id);
}
