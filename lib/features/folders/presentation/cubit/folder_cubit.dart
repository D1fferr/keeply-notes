import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/folder_entity.dart';
import '../../domain/usecases/folder_crud_usecases.dart';
import '../../domain/usecases/watch_folders_usecase.dart';
import '../../../../core/utils/logger.dart';
import 'folder_state.dart';

/// Manages folder navigation, breadcrumb trail, and CRUD operations.
///
/// The cubit subscribes to a Drift stream for the current folder level so the
/// UI reflects database changes in real time.
class FolderCubit extends ChangeNotifier {
  FolderCubit({
    required WatchRootFoldersUseCase watchRootFolders,
    required WatchSubfoldersUseCase watchSubfolders,
    required GetFolderByIdUseCase getFolderById,
    required CreateFolderUseCase createFolder,
    required RenameFolderUseCase renameFolder,
    required MoveFolderUseCase moveFolder,
    required SetFolderProtectionUseCase setFolderProtection,
    required DeleteFolderUseCase deleteFolder,
  })  : _watchRootFolders = watchRootFolders,
        _watchSubfolders = watchSubfolders,
        _getFolderById = getFolderById,
        _createFolder = createFolder,
        _renameFolder = renameFolder,
        _moveFolder = moveFolder,
        _setFolderProtection = setFolderProtection,
        _deleteFolder = deleteFolder {
    _navigateToRoot();
  }

  // ─── Use cases ────────────────────────────────────────────────────────────

  final WatchRootFoldersUseCase _watchRootFolders;
  final WatchSubfoldersUseCase _watchSubfolders;
  final GetFolderByIdUseCase _getFolderById;
  final CreateFolderUseCase _createFolder;
  final RenameFolderUseCase _renameFolder;
  final MoveFolderUseCase _moveFolder;
  final SetFolderProtectionUseCase _setFolderProtection;
  final DeleteFolderUseCase _deleteFolder;

  // ─── State ────────────────────────────────────────────────────────────────

  FolderState _state = FolderInitial();
  FolderState get state => _state;

  StreamSubscription<List<FolderEntity>>? _foldersSub;

  /// Breadcrumb stack maintained internally to support back-navigation.
  final List<BreadcrumbItem> _breadcrumb = [
    const BreadcrumbItem(id: null, name: 'Home'),
  ];

  // ─── Navigation ───────────────────────────────────────────────────────────

  /// Navigates to the root (Home) level.
  void _navigateToRoot() {
    _breadcrumb
      ..clear()
      ..add(const BreadcrumbItem(id: null, name: 'Home'));
    _subscribeToFolders(parentId: null);
  }

  /// Opens a subfolder and pushes it onto the breadcrumb trail.
  Future<void> openFolder(FolderEntity folder) async {
    _breadcrumb.add(BreadcrumbItem(id: folder.id, name: folder.name));
    _subscribeToFolders(parentId: folder.id);
  }

  /// Navigates directly to the breadcrumb item at [index].
  ///
  /// Tapping an intermediate crumb trims the trail back to that point.
  Future<void> navigateToBreadcrumb(int index) async {
    if (index < 0 || index >= _breadcrumb.length) return;
    _breadcrumb.removeRange(index + 1, _breadcrumb.length);
    _subscribeToFolders(parentId: _breadcrumb[index].id);
  }

  /// Pops one level in the breadcrumb (equivalent to pressing Back).
  ///
  /// Returns `true` if navigation happened (there was a parent to go to).
  bool navigateBack() {
    if (_breadcrumb.length <= 1) return false;
    _breadcrumb.removeLast();
    _subscribeToFolders(parentId: _breadcrumb.last.id);
    return true;
  }

  // ─── Stream subscription ──────────────────────────────────────────────────

  void _subscribeToFolders({required String? parentId}) {
    _foldersSub?.cancel();

    _setState(FolderLoading());

    final stream = parentId == null
        ? _watchRootFolders()
        : _watchSubfolders(parentId);

    _foldersSub = stream.listen(
      (folders) {
        _setState(FolderLoaded(
          folders: folders,
          breadcrumb: List.unmodifiable(_breadcrumb),
          currentFolderId: parentId,
        ));
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error('FolderCubit stream error', e, st);
        _setState(FolderError(e.toString()));
      },
    );
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> createFolder(String name, {bool isProtected = false}) async {
    try {
      final parentId = _currentFolderId;
      await _createFolder(
        name: name,
        parentId: parentId,
        isProtected: isProtected,
      );
    } catch (e, st) {
      AppLogger.error('FolderCubit.createFolder failed', e, st);
      _setState(FolderError('Failed to create folder: ${e.toString()}'));
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    try {
      await _renameFolder(id, newName);
    } catch (e, st) {
      AppLogger.error('FolderCubit.renameFolder failed', e, st);
      _setState(FolderError('Failed to rename folder: ${e.toString()}'));
    }
  }

  Future<void> moveFolder(String id, {String? newParentId}) async {
    try {
      await _moveFolder(id, newParentId: newParentId);
    } on ArgumentError catch (e) {
      AppLogger.warning('FolderCubit.moveFolder cycle guard: ${e.message}');
      _setState(FolderError(e.message.toString()));
    } catch (e, st) {
      AppLogger.error('FolderCubit.moveFolder failed', e, st);
      _setState(FolderError('Failed to move folder: ${e.toString()}'));
    }
  }

  Future<void> setFolderProtection(String id,
      {required bool isProtected}) async {
    try {
      await _setFolderProtection(id, isProtected: isProtected);
    } catch (e, st) {
      AppLogger.error('FolderCubit.setFolderProtection failed', e, st);
      _setState(FolderError('Failed to update protection: ${e.toString()}'));
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _deleteFolder(id);
    } catch (e, st) {
      AppLogger.error('FolderCubit.deleteFolder failed', e, st);
      _setState(FolderError('Failed to delete folder: ${e.toString()}'));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String? get _currentFolderId =>
      _breadcrumb.isEmpty ? null : _breadcrumb.last.id;

  void _setState(FolderState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _foldersSub?.cancel();
    super.dispose();
  }
}
