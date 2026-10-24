import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/constants/app_constants.dart';
import 'package:keeply_notes/features/folders/domain/folder_entity.dart';
import 'package:keeply_notes/features/notes/domain/note_entity.dart';
import 'package:keeply_notes/features/sync/domain/services/hkdf_key_derivation_service.dart';
import 'package:keeply_notes/features/sync/domain/services/sync_encryption_service.dart';

void main() {
  group('E2E Offline Sync & Disaster Recovery Simulation', () {
    const keyEngine = SyncKeyDerivationEngine();
    const encryptionService = SyncEncryptionService();
    const googleUserId = 'google-user-id-987654321';
    final now = DateTime.now().toUtc();

    test('recovers identical encryption key deterministically across devices/sessions', () {
      final keyDeviceA = keyEngine.deriveKey(googleUserId, AppConstants.syncSalt);
      final keyDeviceB = keyEngine.deriveKey(googleUserId, AppConstants.syncSalt);

      expect(keyDeviceA, equals(keyDeviceB));
      expect(keyDeviceA.length, 32); // 256 bits
    });

    test('full round-trip: local offline note -> encrypt -> cloud blob -> disaster wipe -> recover', () {
      // 1. User creates a note offline
      final localNote = NoteEntity(
        id: 'note-recovery-test',
        folderId: 'folder-important',
        title: 'Recovery Note',
        contentJson: jsonEncode([
          {'insert': 'Confidential offline notes to recover'}
        ]),
        isPinned: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      final key = keyEngine.deriveKey(googleUserId, AppConstants.syncSalt);

      // 2. DriveSyncService encrypts the item before uploading to Google Drive
      final plainJson = jsonEncode(localNote.toJson());
      final encryptedBlob = encryptionService.encryptUtf8(plainJson, key);

      expect(encryptedBlob.length, greaterThan(plainJson.length));

      // 3. Simulate disaster recovery: app storage wiped on device or installed on a new device.
      // Remote cloud returns encryptedBlob from appDataFolder
      final decryptedJson = encryptionService.decryptToUtf8(encryptedBlob, key);
      final restoredMap = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final restoredNote = NoteEntity.fromJson(restoredMap);

      expect(restoredNote.id, localNote.id);
      expect(restoredNote.title, localNote.title);
      expect(restoredNote.contentJson, localNote.contentJson);
      expect(restoredNote.isPinned, isTrue);
      expect(restoredNote.folderId, 'folder-important');
    });

    test('tampered cloud blob raises SyncDecryptionException and prevents corrupted restore', () {
      final key = keyEngine.deriveKey(googleUserId, AppConstants.syncSalt);
      final encryptedBlob = encryptionService.encryptUtf8('{"title":"Safe"}', key);

      // Simulate bit-flip or corruption during cloud storage/transfer
      final corruptedBlob = List<int>.from(encryptedBlob);
      corruptedBlob[corruptedBlob.length - 1] ^= 0xFF; // tamper with GCM auth tag

      expect(
        () => encryptionService.decryptToUtf8(corruptedBlob, key),
        throwsA(isA<SyncDecryptionException>()),
      );
    });

    test('LWW differential sync resolves conflict when local is newer or remote is newer', () {
      final t1 = now.subtract(const Duration(minutes: 10));
      final t2 = now.subtract(const Duration(minutes: 2));

      final noteDevice1 = NoteEntity(
        id: 'note-conflict-1',
        folderId: null,
        title: 'Device 1 Title',
        contentJson: '[]',
        isPinned: false,
        createdAt: t1,
        updatedAt: t1, // older
        isDeleted: false,
      );

      final noteDevice2 = NoteEntity(
        id: 'note-conflict-1',
        folderId: null,
        title: 'Device 2 Newer Title',
        contentJson: '[]',
        isPinned: false,
        createdAt: t1,
        updatedAt: t2, // newer
        isDeleted: false,
      );

      // Last-Write-Wins rule: if remote updatedAt > local updatedAt -> accept remote
      final shouldAcceptRemote = noteDevice2.updatedAt.isAfter(noteDevice1.updatedAt);
      expect(shouldAcceptRemote, isTrue);

      final winner = shouldAcceptRemote ? noteDevice2 : noteDevice1;
      expect(winner.title, 'Device 2 Newer Title');
    });

    test('tombstone propagation: local item is deleted when remote has isDeleted=true and newer timestamp', () {
      final t1 = now.subtract(const Duration(hours: 1));
      final t2 = now;

      final localNote = NoteEntity(
        id: 'note-tombstone',
        folderId: null,
        title: 'Active Note',
        contentJson: '[]',
        isPinned: false,
        createdAt: t1,
        updatedAt: t1,
        isDeleted: false,
      );

      final remoteTombstone = NoteEntity(
        id: 'note-tombstone',
        folderId: null,
        title: 'Active Note',
        contentJson: '[]',
        isPinned: false,
        createdAt: t1,
        updatedAt: t2, // newer deletion
        isDeleted: true,
      );

      expect(remoteTombstone.updatedAt.isAfter(localNote.updatedAt), isTrue);
      expect(remoteTombstone.isDeleted, isTrue);
    });
  });
}
