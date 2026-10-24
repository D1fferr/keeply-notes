import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/features/sync/domain/services/hkdf_key_derivation_service.dart';
import 'package:keeply_notes/features/sync/domain/services/sync_encryption_service.dart';

void main() {
  group('SyncEncryptionService (AES-256-GCM) Unit Tests (Task 6.2)', () {
    const service = SyncEncryptionService();
    const keyEngine = SyncKeyDerivationEngine();

    late Uint8List validKey;

    setUp(() {
      validKey = keyEngine.deriveKey('test_user_google_id_123');
    });

    test('validates 32-byte key length requirement', () {
      final shortKey = Uint8List(16);
      final longKey = Uint8List(64);
      final plain = Uint8List.fromList([1, 2, 3]);

      expect(
        () => service.encryptPayload(plainBytes: plain, key: shortKey),
        throwsArgumentError,
      );
      expect(
        () => service.encryptPayload(plainBytes: plain, key: longKey),
        throwsArgumentError,
      );
    });

    test('validates payload minimum size requirement', () {
      final invalidPayload = Uint8List(SyncEncryptionService.minPayloadLength - 1);
      expect(
        () => service.decryptPayload(encryptedPayload: invalidPayload, key: validKey),
        throwsA(isA<SyncDecryptionException>()),
      );
    });

    test('roundtrip byte payload encryption and decryption', () {
      final plainBytes = Uint8List.fromList(
        utf8.encode('Top Secret Note Content with 🔒 emoji & unicode accents: äöü'),
      );

      final encrypted = service.encryptPayload(
        plainBytes: plainBytes,
        key: validKey,
      );

      // Verify wire structure: 12 bytes IV + ciphertext with 16 bytes auth tag
      expect(
        encrypted.length,
        equals(SyncEncryptionService.ivLength + plainBytes.length + SyncEncryptionService.tagLength),
      );

      final decrypted = service.decryptPayload(
        encryptedPayload: encrypted,
        key: validKey,
      );

      expect(decrypted, equals(plainBytes));
      expect(utf8.decode(decrypted), utf8.decode(plainBytes));
    });

    test('roundtrip JSON map encryption and decryption', () {
      final noteMap = <String, dynamic>{
        'id': 'note-uuid-999',
        'title': 'Project Ideas',
        'content_json': '[{"insert":"Hello World\\n"}]',
        'is_pinned': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'is_deleted': false,
      };

      final encryptedBlob = service.encryptJson(
        jsonMap: noteMap,
        key: validKey,
      );

      final decryptedMap = service.decryptJson(
        encryptedPayload: encryptedBlob,
        key: validKey,
      );

      expect(decryptedMap['id'], 'note-uuid-999');
      expect(decryptedMap['title'], 'Project Ideas');
      expect(decryptedMap['is_pinned'], isTrue);
      expect(decryptedMap['content_json'], '[{"insert":"Hello World\\n"}]');
    });

    test('roundtrip plain text string encryption and decryption', () {
      const originalString = 'End-to-End Encrypted Cloud Payload';

      final encrypted = service.encryptString(
        plainText: originalString,
        key: validKey,
      );

      final decrypted = service.decryptString(
        encryptedPayload: encrypted,
        key: validKey,
      );

      expect(decrypted, equals(originalString));
    });

    test('roundtrip file encryption and decryption', () async {
      final tempDir = await Directory.systemTemp.createTemp('sync_enc_test_');
      final sourceFile = File('${tempDir.path}/original.bin');
      final encryptedFile = File('${tempDir.path}/encrypted.enc');

      final sampleData = Uint8List.fromList(List.generate(256, (i) => i % 256));
      await sourceFile.writeAsBytes(sampleData);

      await service.encryptFile(
        sourceFile: sourceFile,
        targetFile: encryptedFile,
        key: validKey,
      );

      expect(await encryptedFile.exists(), isTrue);

      final decryptedBytes = await service.decryptFile(
        encryptedFile: encryptedFile,
        key: validKey,
      );

      expect(decryptedBytes, equals(sampleData));

      await tempDir.delete(recursive: true);
    });

    test('custom IV produces reproducible ciphertext', () {
      final plain = Uint8List.fromList(utf8.encode('Predictable IV Test'));
      final customIv = Uint8List.fromList(List.generate(12, (i) => i + 1));

      final enc1 = service.encryptPayload(plainBytes: plain, key: validKey, customIv: customIv);
      final enc2 = service.encryptPayload(plainBytes: plain, key: validKey, customIv: customIv);

      expect(enc1, equals(enc2));

      final decrypted = service.decryptPayload(encryptedPayload: enc1, key: validKey);
      expect(decrypted, equals(plain));
    });

    test('tamper resistance: modified ciphertext fails authentication tag check', () {
      final plain = Uint8List.fromList(utf8.encode('Sensitive Note'));
      final encrypted = service.encryptPayload(plainBytes: plain, key: validKey);

      // Mutate a byte in the ciphertext body
      final tampered = Uint8List.fromList(encrypted);
      tampered[SyncEncryptionService.ivLength + 2] ^= 0xFF;

      expect(
        () => service.decryptPayload(encryptedPayload: tampered, key: validKey),
        throwsA(isA<SyncDecryptionException>()),
      );
    });

    test('tamper resistance: modified IV fails tag check', () {
      final plain = Uint8List.fromList(utf8.encode('Sensitive Note'));
      final encrypted = service.encryptPayload(plainBytes: plain, key: validKey);

      final tampered = Uint8List.fromList(encrypted);
      tampered[0] ^= 0x01; // flip bit in IV

      expect(
        () => service.decryptPayload(encryptedPayload: tampered, key: validKey),
        throwsA(isA<SyncDecryptionException>()),
      );
    });

    test('wrong key fails GCM tag check', () {
      final plain = Uint8List.fromList(utf8.encode('Secret Document'));
      final encrypted = service.encryptPayload(plainBytes: plain, key: validKey);

      final alternateKey = keyEngine.deriveKey('different_google_user_id');

      expect(
        () => service.decryptPayload(encryptedPayload: encrypted, key: alternateKey),
        throwsA(isA<SyncDecryptionException>()),
      );
    });
  });
}
