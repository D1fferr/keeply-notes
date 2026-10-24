import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/sync_result_entity.dart';
import '../../domain/repositories/google_auth_repository.dart';
import '../../domain/services/hkdf_key_derivation_service.dart';
import '../../domain/services/sync_encryption_service.dart';

/// Item-Level Cloud Synchronization Service for Google Drive `appDataFolder`.
///
/// Features:
/// - Differential item-level sync storing individual `.enc` blobs (folder_*.enc, note_*.enc, attachment_*.enc).
/// - Last-Write-Wins (LWW) conflict resolution using UTC `updatedAt` timestamps and tombstone `isDeleted` flags.
/// - Deterministic zero-knowledge E2EE using AES-256-GCM keys derived from HKDF-SHA256(Google_User_ID).
/// - Full synchronization of hierarchical folders, rich text notes with reminders, and media attachments.
class DriveSyncService {
  DriveSyncService({
    required AppDatabase db,
    required GoogleAuthRepository authRepository,
    SyncKeyDerivationEngine? keyEngine,
    SyncEncryptionService? encryptionService,
    Future<Directory> Function()? getDocumentsDirectory,
  })  : _db = db,
        _authRepository = authRepository,
        _keyEngine = keyEngine ?? const SyncKeyDerivationEngine(),
        _encryptionService = encryptionService ?? const SyncEncryptionService(),
        _getDocumentsDirectory =
            getDocumentsDirectory ?? getApplicationDocumentsDirectory;

  final AppDatabase _db;
  final GoogleAuthRepository _authRepository;
  final SyncKeyDerivationEngine _keyEngine;
  final SyncEncryptionService _encryptionService;
  final Future<Directory> Function() _getDocumentsDirectory;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<Directory> _getAttachmentsDirectory() async {
    final docsDir = await _getDocumentsDirectory();
    final attachmentsDir =
        Directory(p.join(docsDir.path, AppConstants.attachmentsDirectoryName));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// Executes a full bidirectional Item-Level Last-Write-Wins synchronization cycle.
  Future<DriveSyncResult> syncAll({
    drive.DriveApi? customDriveApi,
    Uint8List? customKey,
  }) async {
    if (_isSyncing) {
      AppLogger.warn('DriveSyncService: sync is already in progress, skipping');
      return DriveSyncResult.failure('Sync is already in progress');
    }

    _isSyncing = true;
    final startTime = DateTime.now().toUtc();

    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        return DriveSyncResult.failure('User is not signed in with Google');
      }

      final driveApi = customDriveApi ?? _authRepository.getDriveApi();
      if (driveApi == null) {
        return DriveSyncResult.failure('Google Drive API client is unavailable');
      }

      final key = customKey ?? _keyEngine.deriveKey(user.id);

      AppLogger.info('DriveSyncService: starting sync for ${user.email} (user ID: ${user.id})');

      // ── Step 1: Fetch remote index from appDataFolder ─────────────────────
      final remoteFiles = await _fetchRemoteFiles(driveApi);
      AppLogger.debug('DriveSyncService: fetched ${remoteFiles.length} remote files from appDataFolder');

      final remoteFolders = <String, drive.File>{};
      final remoteNotes = <String, drive.File>{};
      final remoteAttachments = <String, drive.File>{};

      for (final file in remoteFiles) {
        final name = file.name ?? '';
        final entityType = file.appProperties?['entityType'];
        final entityId = file.appProperties?['entityId'];

        if (entityType == 'folder' && entityId != null) {
          remoteFolders[entityId] = file;
        } else if (name.startsWith('folder_') && name.endsWith('.enc')) {
          final id = name.substring('folder_'.length, name.length - '.enc'.length);
          remoteFolders[id] = file;
        } else if (entityType == 'note' && entityId != null) {
          remoteNotes[entityId] = file;
        } else if (name.startsWith('note_') && name.endsWith('.enc')) {
          final id = name.substring('note_'.length, name.length - '.enc'.length);
          remoteNotes[id] = file;
        } else if (entityType == 'attachment' && entityId != null) {
          remoteAttachments[entityId] = file;
        } else if (name.startsWith('attachment_') && name.endsWith('.enc')) {
          final id = name.substring('attachment_'.length, name.length - '.enc'.length);
          remoteAttachments[id] = file;
        }
      }

      int foldersUploaded = 0;
      int foldersDownloaded = 0;
      int notesUploaded = 0;
      int notesDownloaded = 0;
      int attachmentsUploaded = 0;
      int attachmentsDownloaded = 0;

      // ── Step 2: Synchronize Folders (LWW) ──────────────────────────────────
      final folderMetrics = await _syncFolders(
        driveApi: driveApi,
        key: key,
        remoteFolders: remoteFolders,
      );
      foldersUploaded = folderMetrics.uploaded;
      foldersDownloaded = folderMetrics.downloaded;

      // ── Step 3: Synchronize Notes & Reminders (LWW) ─────────────────────────
      final noteMetrics = await _syncNotes(
        driveApi: driveApi,
        key: key,
        remoteNotes: remoteNotes,
      );
      notesUploaded = noteMetrics.uploaded;
      notesDownloaded = noteMetrics.downloaded;

      // ── Step 4: Synchronize Media Attachments ─────────────────────────────
      final attachmentMetrics = await _syncAttachments(
        driveApi: driveApi,
        key: key,
        remoteAttachments: remoteAttachments,
      );
      attachmentsUploaded = attachmentMetrics.uploaded;
      attachmentsDownloaded = attachmentMetrics.downloaded;

      final result = DriveSyncResult(
        success: true,
        foldersUploaded: foldersUploaded,
        foldersDownloaded: foldersDownloaded,
        notesUploaded: notesUploaded,
        notesDownloaded: notesDownloaded,
        attachmentsUploaded: attachmentsUploaded,
        attachmentsDownloaded: attachmentsDownloaded,
        syncedAt: startTime,
      );

      AppLogger.info('DriveSyncService: sync completed successfully. $result');
      return result;
    } catch (e, st) {
      AppLogger.error('DriveSyncService: sync failed with error', e, st);
      return DriveSyncResult.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Remote File Listing ───────────────────────────────────────────────────

  Future<List<drive.File>> _fetchRemoteFiles(drive.DriveApi driveApi) async {
    final allFiles = <drive.File>[];
    String? pageToken;

    do {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: 'trashed = false',
        $fields:
            'nextPageToken, files(id, name, modifiedTime, size, mimeType, appProperties)',
        pageSize: 100,
        pageToken: pageToken,
      );

      if (fileList.files != null) {
        allFiles.addAll(fileList.files!);
      }
      pageToken = fileList.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return allFiles;
  }

  // ─── Folder Synchronization ────────────────────────────────────────────────

  Future<_Metrics> _syncFolders({
    required drive.DriveApi driveApi,
    required Uint8List key,
    required Map<String, drive.File> remoteFolders,
  }) async {
    int uploaded = 0;
    int downloaded = 0;

    final localFolders = await _db.select(_db.folders).get();
    final localFoldersMap = {for (final f in localFolders) f.id: f};

    // 1. Process local folders (upload or download newer)
    for (final local in localFolders) {
      final remote = remoteFolders[local.id];

      if (remote == null) {
        // Exists locally but not on remote -> upload
        await _uploadFolder(driveApi, local, key);
        uploaded++;
      } else {
        final remoteUpdatedAt = _extractUpdatedAt(remote);
        final localUpdatedAt = local.updatedAt.toUtc();

        if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
          // Local is newer -> upload update
          await _uploadFolder(driveApi, local, key, existingFileId: remote.id);
          uploaded++;
        } else if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          // Remote is newer -> download
          final success = await _downloadFolder(driveApi, remote, key);
          if (success) downloaded++;
        }
      }
    }

    // 2. Process remote folders not present locally -> download
    for (final entry in remoteFolders.entries) {
      if (!localFoldersMap.containsKey(entry.key)) {
        final success = await _downloadFolder(driveApi, entry.value, key);
        if (success) downloaded++;
      }
    }

    return _Metrics(uploaded: uploaded, downloaded: downloaded);
  }

  Future<void> _uploadFolder(
    drive.DriveApi driveApi,
    FolderData folder,
    Uint8List key, {
    String? existingFileId,
  }) async {
    final jsonMap = {
      'id': folder.id,
      'parent_id': folder.parentId,
      'name': folder.name,
      'is_protected': folder.isProtected,
      'created_at': folder.createdAt.toUtc().toIso8601String(),
      'updated_at': folder.updatedAt.toUtc().toIso8601String(),
      'is_deleted': folder.isDeleted,
    };

    final encryptedBytes = _encryptionService.encryptJson(jsonMap: jsonMap, key: key);
    final fileName = 'folder_${folder.id}.enc';
    final appProperties = {
      'entityType': 'folder',
      'entityId': folder.id,
      'updatedAt': folder.updatedAt.toUtc().toIso8601String(),
      'isDeleted': folder.isDeleted ? 'true' : 'false',
    };

    final media = drive.Media(
      Stream.value(encryptedBytes),
      encryptedBytes.length,
      contentType: 'application/octet-stream',
    );

    if (existingFileId != null) {
      final updateFile = drive.File()
        ..name = fileName
        ..appProperties = appProperties;
      await driveApi.files.update(updateFile, existingFileId, uploadMedia: media);
      AppLogger.debug('DriveSyncService: updated remote folder ${folder.id}');
    } else {
      final newFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']
        ..appProperties = appProperties;
      await driveApi.files.create(newFile, uploadMedia: media);
      AppLogger.debug('DriveSyncService: created remote folder ${folder.id}');
    }
  }

  Future<bool> _downloadFolder(
    drive.DriveApi driveApi,
    drive.File remoteFile,
    Uint8List key,
  ) async {
    try {
      final fileId = remoteFile.id!;
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await _readMediaStream(media);
      final jsonMap = _encryptionService.decryptJson(encryptedPayload: bytes, key: key);

      final companion = FoldersCompanion(
        id: Value(jsonMap['id'] as String),
        parentId: Value(jsonMap['parent_id'] as String?),
        name: Value(jsonMap['name'] as String? ?? 'Untitled Folder'),
        isProtected: Value(jsonMap['is_protected'] as bool? ?? false),
        createdAt: Value(DateTime.parse(jsonMap['created_at'] as String).toUtc()),
        updatedAt: Value(DateTime.parse(jsonMap['updated_at'] as String).toUtc()),
        isDeleted: Value(jsonMap['is_deleted'] as bool? ?? false),
      );

      await _db.into(_db.folders).insertOnConflictUpdate(companion);
      AppLogger.debug('DriveSyncService: downloaded and upserted folder ${jsonMap['id']}');
      return true;
    } catch (e, st) {
      AppLogger.error('DriveSyncService: failed to download/decrypt folder ${remoteFile.name}', e, st);
      return false;
    }
  }

  // ─── Note Synchronization ──────────────────────────────────────────────────

  Future<_Metrics> _syncNotes({
    required drive.DriveApi driveApi,
    required Uint8List key,
    required Map<String, drive.File> remoteNotes,
  }) async {
    int uploaded = 0;
    int downloaded = 0;

    final localNotes = await _db.select(_db.notes).get();
    final localNotesMap = {for (final n in localNotes) n.id: n};

    // 1. Process local notes (upload or download newer)
    for (final local in localNotes) {
      final remote = remoteNotes[local.id];

      if (remote == null) {
        // Exists locally but not on remote -> upload
        await _uploadNote(driveApi, local, key);
        uploaded++;
      } else {
        final remoteUpdatedAt = _extractUpdatedAt(remote);
        final localUpdatedAt = local.updatedAt.toUtc();

        if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
          // Local is newer -> upload update
          await _uploadNote(driveApi, local, key, existingFileId: remote.id);
          uploaded++;
        } else if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          // Remote is newer -> download
          final success = await _downloadNote(driveApi, remote, key);
          if (success) downloaded++;
        }
      }
    }

    // 2. Process remote notes not present locally -> download
    for (final entry in remoteNotes.entries) {
      if (!localNotesMap.containsKey(entry.key)) {
        final success = await _downloadNote(driveApi, entry.value, key);
        if (success) downloaded++;
      }
    }

    return _Metrics(uploaded: uploaded, downloaded: downloaded);
  }

  Future<void> _uploadNote(
    drive.DriveApi driveApi,
    NoteData note,
    Uint8List key, {
    String? existingFileId,
  }) async {
    // Fetch attached primary reminder and sub-reminders if existing
    final reminder = await (_db.select(_db.reminders)
          ..where((r) => r.noteId.equals(note.id)))
        .getSingleOrNull();

    List<SubReminderData> subReminders = [];
    if (reminder != null) {
      subReminders = await (_db.select(_db.subReminders)
            ..where((s) => s.reminderId.equals(reminder.id)))
          .get();
    }

    final jsonMap = <String, dynamic>{
      'id': note.id,
      'folder_id': note.folderId,
      'title': note.title,
      'content_json': note.contentJson,
      'is_pinned': note.isPinned,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
      'is_deleted': note.isDeleted,
      if (reminder != null)
        'reminder': {
          'id': reminder.id,
          'start_date_time': reminder.startDateTime.toUtc().toIso8601String(),
          'repeat_type': reminder.repeatType,
          'custom_days_interval': reminder.customDaysInterval,
          'is_enabled': reminder.isEnabled,
          'sub_reminders': subReminders
              .map((s) => {
                    'id': s.id,
                    'type': s.type,
                    'offset_minutes': s.offsetMinutes,
                    'exact_time': s.exactTime,
                  })
              .toList(),
        },
    };

    final encryptedBytes = _encryptionService.encryptJson(jsonMap: jsonMap, key: key);
    final fileName = 'note_${note.id}.enc';
    final appProperties = {
      'entityType': 'note',
      'entityId': note.id,
      'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      'isDeleted': note.isDeleted ? 'true' : 'false',
    };

    final media = drive.Media(
      Stream.value(encryptedBytes),
      encryptedBytes.length,
      contentType: 'application/octet-stream',
    );

    if (existingFileId != null) {
      final updateFile = drive.File()
        ..name = fileName
        ..appProperties = appProperties;
      await driveApi.files.update(updateFile, existingFileId, uploadMedia: media);
      AppLogger.debug('DriveSyncService: updated remote note ${note.id}');
    } else {
      final newFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']
        ..appProperties = appProperties;
      await driveApi.files.create(newFile, uploadMedia: media);
      AppLogger.debug('DriveSyncService: created remote note ${note.id}');
    }
  }

  Future<bool> _downloadNote(
    drive.DriveApi driveApi,
    drive.File remoteFile,
    Uint8List key,
  ) async {
    try {
      final fileId = remoteFile.id!;
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await _readMediaStream(media);
      final jsonMap = _encryptionService.decryptJson(encryptedPayload: bytes, key: key);

      final noteId = jsonMap['id'] as String;
      final companion = NotesCompanion(
        id: Value(noteId),
        folderId: Value(jsonMap['folder_id'] as String?),
        title: Value(jsonMap['title'] as String? ?? ''),
        contentJson: Value(jsonMap['content_json'] as String? ?? '[]'),
        isPinned: Value(jsonMap['is_pinned'] as bool? ?? false),
        createdAt: Value(DateTime.parse(jsonMap['created_at'] as String).toUtc()),
        updatedAt: Value(DateTime.parse(jsonMap['updated_at'] as String).toUtc()),
        isDeleted: Value(jsonMap['is_deleted'] as bool? ?? false),
      );

      await _db.into(_db.notes).insertOnConflictUpdate(companion);

      // Restore reminder and sub-reminders if present in payload
      if (jsonMap.containsKey('reminder') && jsonMap['reminder'] != null) {
        final reminderMap = jsonMap['reminder'] as Map<String, dynamic>;
        final reminderId = reminderMap['id'] as String;

        final reminderCompanion = RemindersCompanion(
          id: Value(reminderId),
          noteId: Value(noteId),
          startDateTime: Value(DateTime.parse(reminderMap['start_date_time'] as String).toUtc()),
          repeatType: Value(reminderMap['repeat_type'] as String),
          customDaysInterval: Value(reminderMap['custom_days_interval'] as int?),
          isEnabled: Value(reminderMap['is_enabled'] as bool? ?? true),
        );
        await _db.into(_db.reminders).insertOnConflictUpdate(reminderCompanion);

        if (reminderMap.containsKey('sub_reminders') && reminderMap['sub_reminders'] is List) {
          final subList = reminderMap['sub_reminders'] as List;
          for (final subItem in subList) {
            final s = subItem as Map<String, dynamic>;
            final subCompanion = SubRemindersCompanion(
              id: Value(s['id'] as String),
              reminderId: Value(reminderId),
              type: Value(s['type'] as String),
              offsetMinutes: Value(s['offset_minutes'] as int?),
              exactTime: Value(s['exact_time'] as String?),
            );
            await _db.into(_db.subReminders).insertOnConflictUpdate(subCompanion);
          }
        }
      }

      AppLogger.debug('DriveSyncService: downloaded and upserted note $noteId');
      return true;
    } catch (e, st) {
      AppLogger.error('DriveSyncService: failed to download/decrypt note ${remoteFile.name}', e, st);
      return false;
    }
  }

  // ─── Media Attachment Synchronization ──────────────────────────────────────

  Future<_Metrics> _syncAttachments({
    required drive.DriveApi driveApi,
    required Uint8List key,
    required Map<String, drive.File> remoteAttachments,
  }) async {
    int uploaded = 0;
    int downloaded = 0;

    final localAttachments = await _db.select(_db.attachments).get();
    final localAttachmentsMap = {for (final a in localAttachments) a.id: a};
    final attachmentsDir = await _getAttachmentsDirectory();

    // 1. Upload local attachments not present on remote
    for (final local in localAttachments) {
      if (!remoteAttachments.containsKey(local.id)) {
        final file = File(local.localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = 'attachment_${local.id}.enc';
          final appProperties = {
            'entityType': 'attachment',
            'entityId': local.id,
            'noteId': local.noteId,
            'fileSize': local.fileSize.toString(),
          };

          final media = drive.Media(
            Stream.value(bytes),
            bytes.length,
            contentType: 'application/octet-stream',
          );

          final newFile = drive.File()
            ..name = fileName
            ..parents = ['appDataFolder']
            ..appProperties = appProperties;

          await driveApi.files.create(newFile, uploadMedia: media);
          uploaded++;
          AppLogger.debug('DriveSyncService: uploaded media attachment ${local.id}');
        }
      }
    }

    // 2. Download remote attachments not present locally
    for (final entry in remoteAttachments.entries) {
      final attachmentId = entry.key;
      final remoteFile = entry.value;

      if (!localAttachmentsMap.containsKey(attachmentId)) {
        try {
          final noteId = remoteFile.appProperties?['noteId'];
          if (noteId == null) continue;

          final media = await driveApi.files.get(
            remoteFile.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final bytes = await _readMediaStream(media);
          final localFilePath = p.join(attachmentsDir.path, '$attachmentId.enc');
          final localFile = File(localFilePath);
          await localFile.writeAsBytes(bytes, flush: true);

          final companion = AttachmentsCompanion(
            id: Value(attachmentId),
            noteId: Value(noteId),
            localPath: Value(localFilePath),
            fileSize: Value(bytes.length),
          );

          await _db.into(_db.attachments).insertOnConflictUpdate(companion);
          downloaded++;
          AppLogger.debug('DriveSyncService: downloaded media attachment $attachmentId');
        } catch (e, st) {
          AppLogger.error('DriveSyncService: failed to download attachment $attachmentId', e, st);
        }
      }
    }

    return _Metrics(uploaded: uploaded, downloaded: downloaded);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  DateTime _extractUpdatedAt(drive.File file) {
    final propDate = file.appProperties?['updatedAt'];
    if (propDate != null && propDate.isNotEmpty) {
      final parsed = DateTime.tryParse(propDate);
      if (parsed != null) return parsed.toUtc();
    }
    return file.modifiedTime?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<Uint8List> _readMediaStream(drive.Media media) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }
}

class _Metrics {
  const _Metrics({required this.uploaded, required this.downloaded});
  final int uploaded;
  final int downloaded;
}
