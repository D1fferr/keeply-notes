import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:keeply_notes/core/database/app_database.dart';
import 'package:keeply_notes/features/sync/data/services/drive_sync_service.dart';
import 'package:keeply_notes/features/sync/domain/entities/google_user_entity.dart';
import 'package:keeply_notes/features/sync/domain/repositories/google_auth_repository.dart';
import 'package:keeply_notes/features/sync/domain/services/hkdf_key_derivation_service.dart';
import 'package:keeply_notes/features/sync/domain/services/sync_encryption_service.dart';

class FakeFilesResource extends Fake implements drive.FilesResource {
  final Map<String, drive.File> remoteFiles = {};
  final Map<String, List<int>> fileContents = {};
  int _idCounter = 1;

  @override
  Future<drive.FileList> list({
    String? spaces,
    String? q,
    String? $fields,
    int? pageSize,
    String? pageToken,
    bool? includeItemsFromAllDrives,
    bool? supportsAllDrives,
  }) async {
    return drive.FileList(files: remoteFiles.values.toList());
  }

  @override
  Future<drive.File> create(
    drive.File request, {
    drive.UploadOptions uploadOptions = drive.UploadOptions.defaultOptions,
    drive.Media? uploadMedia,
    String? $fields,
    bool? ignoreDefaultVisibility,
    bool? keepRevisionForever,
    String? ocrLanguage,
    bool? supportsAllDrives,
    bool? useContentAsIndexableText,
  }) async {
    final fileId = 'drive_file_${_idCounter++}';
    request.id = fileId;
    request.modifiedTime = DateTime.now().toUtc();
    remoteFiles[fileId] = request;

    if (uploadMedia != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in uploadMedia.stream) {
        builder.add(chunk);
      }
      fileContents[fileId] = builder.toBytes();
    }

    return request;
  }

  @override
  Future<drive.File> update(
    drive.File request,
    String fileId, {
    drive.UploadOptions uploadOptions = drive.UploadOptions.defaultOptions,
    drive.Media? uploadMedia,
    String? $fields,
    String? addParents,
    bool? keepRevisionForever,
    String? ocrLanguage,
    String? removeParents,
    bool? supportsAllDrives,
    bool? useContentAsIndexableText,
  }) async {
    final existing = remoteFiles[fileId] ?? request;
    existing.name = request.name ?? existing.name;
    existing.appProperties = request.appProperties ?? existing.appProperties;
    existing.modifiedTime = DateTime.now().toUtc();

    if (uploadMedia != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in uploadMedia.stream) {
        builder.add(chunk);
      }
      fileContents[fileId] = builder.toBytes();
    }

    remoteFiles[fileId] = existing;
    return existing;
  }

  @override
  Future<Object> get(
    String fileId, {
    drive.DownloadOptions downloadOptions = drive.DownloadOptions.metadata,
    String? $fields,
    bool? acknowledgeAbuse,
    bool? supportsAllDrives,
  }) async {
    if (downloadOptions == drive.DownloadOptions.fullMedia) {
      final bytes = fileContents[fileId] ?? const <int>[];
      return drive.Media(Stream.value(bytes), bytes.length);
    }
    return remoteFiles[fileId]!;
  }
}

class FakeDriveApi extends Fake implements drive.DriveApi {
  FakeDriveApi({FakeFilesResource? files})
      : _files = files ?? FakeFilesResource();

  final FakeFilesResource _files;

  @override
  drive.FilesResource get files => _files;
}

class FakeGoogleAuthRepository implements GoogleAuthRepository {
  FakeGoogleAuthRepository({this.currentUser});

  @override
  GoogleUserEntity? currentUser;

  drive.DriveApi? driveApi;

  @override
  Stream<GoogleUserEntity?> get authStateChanges =>
      Stream.value(currentUser);

  @override
  bool get isSignedIn => currentUser != null;

  @override
  Future<GoogleUserEntity?> signIn() async => currentUser;

  @override
  Future<GoogleUserEntity?> signInSilently() async => currentUser;

  @override
  Future<void> signOut() async => currentUser = null;

  @override
  Future<void> disconnect() async => currentUser = null;

  @override
  Future<Map<String, String>> getAuthHeaders({bool forceRefresh = false}) async =>
      {'Authorization': 'Bearer test-token'};

  @override
  Future<void> clearAuthCache() async {}

  @override
  drive.DriveApi? getDriveApi() => driveApi;
}

void main() {
  group('DriveSyncService Item-Level LWW Sync Tests (Task 6.3)', () {
    late AppDatabase db;
    late FakeFilesResource fakeFiles;
    late FakeDriveApi fakeDriveApi;
    late FakeGoogleAuthRepository fakeAuth;
    late DriveSyncService syncService;
    late Directory tempDir;
    late Uint8List syncKey;

    const keyEngine = SyncKeyDerivationEngine();
    const encryptionService = SyncEncryptionService();

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      fakeFiles = FakeFilesResource();
      fakeDriveApi = FakeDriveApi(files: fakeFiles);

      const user = GoogleUserEntity(
        id: 'user_sync_test_123',
        email: 'tester@example.com',
        displayName: 'Test User',
      );

      fakeAuth = FakeGoogleAuthRepository(currentUser: user)..driveApi = fakeDriveApi;
      tempDir = await Directory.systemTemp.createTemp('keeply_sync_test_');

      syncKey = keyEngine.deriveKey(user.id);

      syncService = DriveSyncService(
        db: db,
        authRepository: fakeAuth,
        keyEngine: keyEngine,
        encryptionService: encryptionService,
        getDocumentsDirectory: () async => tempDir,
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('fails gracefully when user is unauthenticated', () async {
      fakeAuth.currentUser = null;

      final result = await syncService.syncAll();

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('User is not signed in'));
    });

    test('syncFolders: uploads local folder when missing on remote', () async {
      final now = DateTime.now().toUtc();
      await db.into(db.folders).insert(FoldersCompanion(
            id: const Value('folder-1'),
            name: const Value('Work Projects'),
            isProtected: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
            isDeleted: const Value(false),
          ));

      final result = await syncService.syncAll(
        customDriveApi: fakeDriveApi,
        customKey: syncKey,
      );

      expect(result.success, isTrue);
      expect(result.foldersUploaded, 1);
      expect(result.foldersDownloaded, 0);

      // Verify remote file was created in appDataFolder
      expect(fakeFiles.remoteFiles.length, 1);
      final createdFile = fakeFiles.remoteFiles.values.first;
      expect(createdFile.name, 'folder_folder-1.enc');
      expect(createdFile.appProperties?['entityType'], 'folder');
      expect(createdFile.appProperties?['entityId'], 'folder-1');

      // Verify content is decryptable
      final bytes = Uint8List.fromList(fakeFiles.fileContents[createdFile.id!]!);
      final decrypted = encryptionService.decryptJson(encryptedPayload: bytes, key: syncKey);
      expect(decrypted['name'], 'Work Projects');
    });

    test('syncFolders: downloads remote folder when missing locally', () async {
      final remoteUpdatedAt = DateTime.now().toUtc();
      final folderData = {
        'id': 'folder-remote-99',
        'parent_id': null,
        'name': 'Cloud Folder',
        'is_protected': true,
        'created_at': remoteUpdatedAt.toIso8601String(),
        'updated_at': remoteUpdatedAt.toIso8601String(),
        'is_deleted': false,
      };

      final encrypted = encryptionService.encryptJson(jsonMap: folderData, key: syncKey);

      await fakeFiles.create(
        drive.File()
          ..name = 'folder_folder-remote-99.enc'
          ..parents = ['appDataFolder']
          ..appProperties = {
            'entityType': 'folder',
            'entityId': 'folder-remote-99',
            'updatedAt': remoteUpdatedAt.toIso8601String(),
            'isDeleted': 'false',
          },
        uploadMedia: drive.Media(Stream.value(encrypted), encrypted.length),
      );

      final result = await syncService.syncAll(
        customDriveApi: fakeDriveApi,
        customKey: syncKey,
      );

      expect(result.success, isTrue);
      expect(result.foldersDownloaded, 1);

      // Verify local database has folder
      final localFolder = await (db.select(db.folders)..where((f) => f.id.equals('folder-remote-99')))
          .getSingleOrNull();

      expect(localFolder, isNotNull);
      expect(localFolder!.name, 'Cloud Folder');
      expect(localFolder.isProtected, isTrue);
    });

    test('syncNotes (LWW): updates remote when local is newer', () async {
      final olderTime = DateTime.utc(2026, 1, 1, 10, 0);
      final newerTime = DateTime.utc(2026, 1, 1, 12, 0);

      // Remote has older note
      final remoteData = {
        'id': 'note-1',
        'folder_id': null,
        'title': 'Old Remote Title',
        'content_json': '[]',
        'is_pinned': false,
        'created_at': olderTime.toIso8601String(),
        'updated_at': olderTime.toIso8601String(),
        'is_deleted': false,
      };
      final encryptedOld = encryptionService.encryptJson(jsonMap: remoteData, key: syncKey);
      final remoteFile = await fakeFiles.create(
        drive.File()
          ..name = 'note_note-1.enc'
          ..parents = ['appDataFolder']
          ..appProperties = {
            'entityType': 'note',
            'entityId': 'note-1',
            'updatedAt': olderTime.toIso8601String(),
            'isDeleted': 'false',
          },
        uploadMedia: drive.Media(Stream.value(encryptedOld), encryptedOld.length),
      );

      // Local has newer note
      await db.into(db.notes).insert(NotesCompanion(
            id: const Value('note-1'),
            title: const Value('Newer Local Title'),
            contentJson: const Value('[{"insert":"Updated"}]'),
            isPinned: const Value(true),
            createdAt: Value(olderTime),
            updatedAt: Value(newerTime),
            isDeleted: const Value(false),
          ));

      final result = await syncService.syncAll(
        customDriveApi: fakeDriveApi,
        customKey: syncKey,
      );

      expect(result.success, isTrue);
      expect(result.notesUploaded, 1);
      expect(result.notesDownloaded, 0);

      // Verify remote file was updated with newer title
      final updatedBytes = Uint8List.fromList(fakeFiles.fileContents[remoteFile.id!]!);
      final decrypted = encryptionService.decryptJson(encryptedPayload: updatedBytes, key: syncKey);
      expect(decrypted['title'], 'Newer Local Title');
      expect(decrypted['is_pinned'], isTrue);
    });

    test('syncNotes (LWW): updates local when remote is newer and restores reminder', () async {
      final olderTime = DateTime.utc(2026, 1, 1, 10, 0);
      final newerTime = DateTime.utc(2026, 1, 1, 14, 0);

      // Local has older note
      await db.into(db.notes).insert(NotesCompanion(
            id: const Value('note-rem-1'),
            title: const Value('Local Old Title'),
            contentJson: const Value('[]'),
            createdAt: Value(olderTime),
            updatedAt: Value(olderTime),
            isDeleted: const Value(false),
          ));

      // Remote has newer note with an active reminder
      final remoteData = {
        'id': 'note-rem-1',
        'folder_id': null,
        'title': 'Remote New Title with Reminder',
        'content_json': '[{"insert":"Cloud note content\\n"}]',
        'is_pinned': false,
        'created_at': olderTime.toIso8601String(),
        'updated_at': newerTime.toIso8601String(),
        'is_deleted': false,
        'reminder': {
          'id': 'rem-uuid-1',
          'start_date_time': '2026-10-20T10:00:00.000Z',
          'repeat_type': 'daily',
          'custom_days_interval': null,
          'is_enabled': true,
          'sub_reminders': [
            {
              'id': 'sub-rem-1',
              'type': 'offset_minutes',
              'offset_minutes': 15,
              'exact_time': null,
            }
          ],
        },
      };

      final encrypted = encryptionService.encryptJson(jsonMap: remoteData, key: syncKey);
      await fakeFiles.create(
        drive.File()
          ..name = 'note_note-rem-1.enc'
          ..parents = ['appDataFolder']
          ..appProperties = {
            'entityType': 'note',
            'entityId': 'note-rem-1',
            'updatedAt': newerTime.toIso8601String(),
            'isDeleted': 'false',
          },
        uploadMedia: drive.Media(Stream.value(encrypted), encrypted.length),
      );

      final result = await syncService.syncAll(
        customDriveApi: fakeDriveApi,
        customKey: syncKey,
      );

      expect(result.success, isTrue);
      expect(result.notesDownloaded, 1);

      // Verify local note updated
      final updatedLocal = await (db.select(db.notes)..where((n) => n.id.equals('note-rem-1'))).getSingle();
      expect(updatedLocal.title, 'Remote New Title with Reminder');

      // Verify reminder and sub-reminder restored locally
      final reminder = await (db.select(db.reminders)..where((r) => r.noteId.equals('note-rem-1'))).getSingleOrNull();
      expect(reminder, isNotNull);
      expect(reminder!.repeatType, 'daily');

      final subReminders = await (db.select(db.subReminders)..where((s) => s.reminderId.equals(reminder.id))).get();
      expect(subReminders.length, 1);
      expect(subReminders.first.offsetMinutes, 15);
    });

    test('syncAttachments: uploads local media and downloads remote media', () async {
      // 1. Create a local attachment
      final localFile = File('${tempDir.path}/local_att.enc');
      await localFile.writeAsBytes([10, 20, 30, 40]);

      await db.into(db.notes).insert(NotesCompanion(
            id: const Value('note-with-media'),
            title: const Value('Media Note'),
            contentJson: const Value('[]'),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.attachments).insert(AttachmentsCompanion(
            id: const Value('att-local-1'),
            noteId: const Value('note-with-media'),
            localPath: Value(localFile.path),
            fileSize: const Value(4),
          ));

      // 2. Create a remote attachment for note-with-media
      final remoteMediaBytes = [99, 88, 77, 66];
      await fakeFiles.create(
        drive.File()
          ..name = 'attachment_att-remote-2.enc'
          ..parents = ['appDataFolder']
          ..appProperties = {
            'entityType': 'attachment',
            'entityId': 'att-remote-2',
            'noteId': 'note-with-media',
            'fileSize': '4',
          },
        uploadMedia: drive.Media(Stream.value(remoteMediaBytes), 4),
      );

      final result = await syncService.syncAll(
        customDriveApi: fakeDriveApi,
        customKey: syncKey,
      );

      expect(result.success, isTrue);
      expect(result.attachmentsUploaded, 1);
      expect(result.attachmentsDownloaded, 1);

      // Verify remote has uploaded local attachment
      final uploadedFile = fakeFiles.remoteFiles.values.firstWhere((f) => f.name == 'attachment_att-local-1.enc');
      expect(uploadedFile, isNotNull);

      // Verify local database has downloaded remote attachment
      final downloadedRecord = await (db.select(db.attachments)..where((a) => a.id.equals('att-remote-2'))).getSingleOrNull();
      expect(downloadedRecord, isNotNull);
      expect(File(downloadedRecord!.localPath).existsSync(), isTrue);
      expect(await File(downloadedRecord.localPath).readAsBytes(), remoteMediaBytes);
    });
  });
}
