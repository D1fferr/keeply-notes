import 'package:flutter/foundation.dart';
import '../../domain/folder_entity.dart';

/// Represents a single step in the breadcrumb navigation trail.
@immutable
class BreadcrumbItem {
  const BreadcrumbItem({required this.id, required this.name});

  /// The folder's UUID. `null` means "Home / root level".
  final String? id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreadcrumbItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── States ──────────────────────────────────────────────────────────────────

@immutable
sealed class FolderState {}

/// Initial state before any data has loaded.
final class FolderInitial extends FolderState {}

/// Data is being loaded.
final class FolderLoading extends FolderState {}

/// Folders and breadcrumb are ready to display.
final class FolderLoaded extends FolderState {
  FolderLoaded({
    required this.folders,
    required this.breadcrumb,
    required this.currentFolderId,
  });

  /// Direct children of the current folder (or root-level folders).
  final List<FolderEntity> folders;

  /// Navigation trail from root to the current folder.
  /// First item is always the "Home" root crumb.
  final List<BreadcrumbItem> breadcrumb;

  /// `null` means we are at the root (Home) level.
  final String? currentFolderId;

  FolderLoaded copyWith({
    List<FolderEntity>? folders,
    List<BreadcrumbItem>? breadcrumb,
    String? Function()? currentFolderId,
  }) {
    return FolderLoaded(
      folders: folders ?? this.folders,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      currentFolderId:
          currentFolderId != null ? currentFolderId() : this.currentFolderId,
    );
  }
}

/// An error occurred while loading or mutating folders.
final class FolderError extends FolderState {
  const FolderError(this.message);

  final String message;
}
