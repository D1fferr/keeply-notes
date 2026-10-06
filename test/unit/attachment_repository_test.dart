import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/database/app_database.dart';
import 'package:keeply_notes/core/services/encryption_service.dart';
import 'package:keeply_notes/core/services/secure_storage_service.dart';
import 'package:keeply_notes/features/notes/data/datasources/attachment_local_data_source_impl.dart';
import 'package:keeply_notes/features/notes/data/repositories/attachment_repository_impl.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<String> getOrCreateAttachmentKey() async {
    return _store.putIfAbsent(
      'attachment_key',
      () => base64UrlEncode(List<int>.generate(32, (i) => (i * 3 + 5) % 256)),
    );
  }
}

void main() {
  group('AttachmentRepository & Disk Encryption Unit Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late AttachmentLocalDataSourceImpl dataSource;
    late FakeSecureStorageService fakeSecureStorage;
    late AttachmentRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('keeply_att_test_');
      dataSource = AttachmentLocalDataSourceImpl(db);
      fakeSecureStorage = FakeSecureStorageService();

      repository = AttachmentRepositoryImpl(
        dataSource: dataSource,
        encryptionService: const EncryptionService(),
        secureStorageService: fakeSecureStorage,
        getDocumentsDirectory: () async => tempDir,
      );

      // Create a test note in db to satisfy foreign key constraints
      final now = DateTime.now();
      await db.into(db.notes).insert(
        NoteData(
          id: 'note-1',
          title: 'Test Note',
          contentJson: '[]',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveAttachment encrypts media bytes to disk and creates db entry', () async {
      final sampleImageBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG magic bytes
        10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
      ]);

      final attachment = await repository.saveAttachment(
        noteId: 'note-1',
        rawBytes: sampleImageBytes,
        fileExtension: 'jpg',
      );

      expect(attachment.id, isNotEmpty);
      expect(attachment.noteId, equals('note-1'));
      expect(attachment.fileSize, equals(sampleImageBytes.length));
      expect(attachment.localPath.endsWith('.enc'), isTrue);

      // Verify file exists on disk
      final fileOnDisk = File(attachment.localPath);
      expect(await fileOnDisk.exists(), isTrue);

      // Verify file on disk is encrypted (does NOT match plain bytes)
      final diskBytes = await fileOnDisk.readAsBytes();
      expect(diskBytes, isNot(equals(sampleImageBytes)));

      // Verify database record exists
      final inDb = await dataSource.getAttachmentById(attachment.id);
      expect(inDb, isNotNull);
      expect(inDb!.id, equals(attachment.id));
    });

    test('getDecryptedAttachmentBytes correctly decrypts encrypted file', () async {
      final sampleBytes = Uint8List.fromList(
        List<int>.generate(256, (i) => (i * 11) % 256),
      );

      final attachment = await repository.saveAttachment(
        noteId: 'note-1',
        rawBytes: sampleBytes,
      );

      final decrypted = await repository.getDecryptedAttachmentBytes(attachment.localPath);
      expect(decrypted, equals(sampleBytes));
    });

    test('getAttachmentsForNote and watchAttachmentsForNote return saved items', () async {
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6]);

      await repository.saveAttachment(noteId: 'note-1', rawBytes: bytes1);
      await repository.saveAttachment(noteId: 'note-1', rawBytes: bytes2);

      final list = await repository.getAttachmentsForNote('note-1');
      expect(list.length, equals(2));

      final streamList = await repository.watchAttachmentsForNote('note-1').first;
      expect(streamList.length, equals(2));
    });

    test('deleteAttachment removes database entry and deletes encrypted file from disk', () async {
      final sampleBytes = Uint8List.fromList([10, 20, 30, 40]);

      final attachment = await repository.saveAttachment(
        noteId: 'note-1',
        rawBytes: sampleBytes,
      );

      final fileOnDisk = File(attachment.localPath);
      expect(await fileOnDisk.exists(), isTrue);

      await repository.deleteAttachment(attachment.id);

      // Database entry removed
      final inDb = await dataSource.getAttachmentById(attachment.id);
      expect(inDb, isNull);

      // Disk file deleted
      expect(await fileOnDisk.exists(), isFalse);
    });

    test('deleteAttachmentsForNote cleans up all files for note', () async {
      final att1 = await repository.saveAttachment(noteId: 'note-1', rawBytes: Uint8List.fromList([1, 2]));
      final att2 = await repository.saveAttachment(noteId: 'note-1', rawBytes: Uint8List.fromList([3, 4]));

      expect(await File(att1.localPath).exists(), isTrue);
      expect(await File(att2.localPath).exists(), isTrue);

      await repository.deleteAttachmentsForNote('note-1');

      final remaining = await repository.getAttachmentsForNote('note-1');
      expect(remaining, isEmpty);

      expect(await File(att1.localPath).exists(), isFalse);
      expect(await File(att2.localPath).exists(), isFalse);
    });
  });
}
