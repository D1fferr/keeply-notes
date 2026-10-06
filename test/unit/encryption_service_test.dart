import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/services/encryption_service.dart';

void main() {
  group('EncryptionService Unit Tests (AES-256-CTR Stream Encryption)', () {
    const encryptionService = EncryptionService();

    // 32-byte test key (256-bit) encoded as base64
    final testKeyBytes = List<int>.generate(32, (i) => i + 1);
    final testKeyBase64 = base64UrlEncode(testKeyBytes);

    test('encryptBytes produces IV + ciphertext of correct length', () {
      final plainText = 'Keeply Notes Secret Image Payload';
      final plainBytes = Uint8List.fromList(utf8.encode(plainText));

      final encrypted = encryptionService.encryptBytes(plainBytes, testKeyBase64);

      // IV length is 16 bytes. In CTR stream mode, ciphertext length == plaintext length.
      expect(encrypted.length, equals(16 + plainBytes.length));
      // Ciphertext must differ from plaintext
      expect(encrypted.sublist(16), isNot(equals(plainBytes)));
    });

    test('encryptBytes produces different ciphertexts for identical input (random IV)', () {
      final plainBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      final enc1 = encryptionService.encryptBytes(plainBytes, testKeyBase64);
      final enc2 = encryptionService.encryptBytes(plainBytes, testKeyBase64);

      // IVs must be different
      expect(enc1.sublist(0, 16), isNot(equals(enc2.sublist(0, 16))));
      // Total payloads must be different
      expect(enc1, isNot(equals(enc2)));
    });

    test('decryptBytes restores exact original bytes', () {
      // Mock binary image data (e.g. 512 bytes with varied values)
      final originalBytes = Uint8List.fromList(
        List<int>.generate(512, (index) => (index * 17 + 3) % 256),
      );

      final encrypted = encryptionService.encryptBytes(originalBytes, testKeyBase64);
      final decrypted = encryptionService.decryptBytes(encrypted, testKeyBase64);

      expect(decrypted, equals(originalBytes));
    });

    test('decryptBytes throws on payload shorter than IV', () {
      final invalidPayload = Uint8List.fromList([1, 2, 3]);
      expect(
        () => encryptionService.decryptBytes(invalidPayload, testKeyBase64),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encryptFile and decryptFile work with local files on disk', () async {
      final tempDir = await Directory.systemTemp.createTemp('keeply_enc_test_');

      try {
        final sourceFile = File('${tempDir.path}/sample_image.png');
        final targetEncryptedFile = File('${tempDir.path}/sample_image.enc');

        final sampleImageBytes = Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG magic header
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
        ]);

        await sourceFile.writeAsBytes(sampleImageBytes);

        // Encrypt file
        await encryptionService.encryptFile(
          sourceFile: sourceFile,
          targetFile: targetEncryptedFile,
          base64Key: testKeyBase64,
        );

        expect(await targetEncryptedFile.exists(), isTrue);
        final fileOnDiskBytes = await targetEncryptedFile.readAsBytes();
        // File on disk must be encrypted and not contain plain PNG header at index 0
        expect(fileOnDiskBytes.sublist(0, 8), isNot(equals(sampleImageBytes.sublist(0, 8))));

        // Decrypt file
        final decryptedBytes = await encryptionService.decryptFile(
          encryptedFile: targetEncryptedFile,
          base64Key: testKeyBase64,
        );

        expect(decryptedBytes, equals(sampleImageBytes));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
