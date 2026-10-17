import 'package:flutter/foundation.dart';

/// Summary report returned after a complete or partial item-level sync cycle.
@immutable
class DriveSyncResult {
  const DriveSyncResult({
    required this.success,
    this.foldersUploaded = 0,
    this.foldersDownloaded = 0,
    this.notesUploaded = 0,
    this.notesDownloaded = 0,
    this.attachmentsUploaded = 0,
    this.attachmentsDownloaded = 0,
    this.errorMessage,
    required this.syncedAt,
  });

  /// Factory for a failed sync attempt.
  factory DriveSyncResult.failure(String error) {
    return DriveSyncResult(
      success: false,
      errorMessage: error,
      syncedAt: DateTime.now().toUtc(),
    );
  }

  /// Factory for an empty / no-op sync (e.g. user not signed in).
  factory DriveSyncResult.empty() {
    return DriveSyncResult(
      success: true,
      syncedAt: DateTime.now().toUtc(),
    );
  }

  final bool success;
  final int foldersUploaded;
  final int foldersDownloaded;
  final int notesUploaded;
  final int notesDownloaded;
  final int attachmentsUploaded;
  final int attachmentsDownloaded;
  final String? errorMessage;
  final DateTime syncedAt;

  int get totalUploaded =>
      foldersUploaded + notesUploaded + attachmentsUploaded;
  int get totalDownloaded =>
      foldersDownloaded + notesDownloaded + attachmentsDownloaded;
  int get totalChanges => totalUploaded + totalDownloaded;

  @override
  String toString() =>
      'DriveSyncResult(success: $success, uploaded: $totalUploaded, downloaded: $totalDownloaded, error: $errorMessage)';
}
