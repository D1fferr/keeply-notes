import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import '../utils/logger.dart';

/// Cryptographic service providing AES-256 stream encryption for local media attachments.
///
/// Uses AES in Counter (CTR) mode (RFC 3686 / NIST SP 800-38A), turning the AES block
/// cipher into a stream cipher with zero padding requirements.
///
/// File storage format:
/// [16-byte random IV] + [AES-256-CTR Ciphertext bytes]
class EncryptionService {
  const EncryptionService();

  static const int ivLength = 16;
  static const int keyLength = 32; // 256 bits

  /// Parses and validates a 32-byte (256-bit) encryption key from base64/base64Url.
  enc.Key _parseKey(String base64Key) {
    Uint8List rawBytes;
    try {
      rawBytes = base64Url.decode(base64Key);
    } catch (_) {
      rawBytes = base64.decode(base64Key);
    }

    if (rawBytes.length != keyLength) {
      throw ArgumentError(
        'Invalid key length: expected $keyLength bytes (256 bits), got ${rawBytes.length}',
      );
    }
    return enc.Key(rawBytes);
  }

  /// Encrypts [plainBytes] using AES-256-CTR and prepends a cryptographically secure 16-byte IV.
  Uint8List encryptBytes(Uint8List plainBytes, String base64Key) {
    final key = _parseKey(base64Key);
    final iv = enc.IV.fromSecureRandom(ivLength);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ctr, padding: null));

    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    final combined = Uint8List(ivLength + encrypted.bytes.length);
    combined.setRange(0, ivLength, iv.bytes);
    combined.setRange(ivLength, combined.length, encrypted.bytes);

    return combined;
  }

  /// Decrypts [encryptedDataWithIv] using AES-256-CTR by extracting the first 16 bytes as IV.
  Uint8List decryptBytes(Uint8List encryptedDataWithIv, String base64Key) {
    if (encryptedDataWithIv.length < ivLength) {
      throw ArgumentError(
        'Invalid encrypted payload: size must be at least $ivLength bytes for IV',
      );
    }

    final key = _parseKey(base64Key);
    final ivBytes = encryptedDataWithIv.sublist(0, ivLength);
    final cipherBytes = encryptedDataWithIv.sublist(ivLength);

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ctr, padding: null));

    final decryptedList = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    return Uint8List.fromList(decryptedList);
  }

  /// Encrypts [sourceFile] and writes the encrypted payload to [targetFile].
  Future<File> encryptFile({
    required File sourceFile,
    required File targetFile,
    required String base64Key,
  }) async {
    try {
      final plainBytes = await sourceFile.readAsBytes();
      final encryptedBytes = encryptBytes(plainBytes, base64Key);

      // Ensure parent directory exists
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      await targetFile.writeAsBytes(encryptedBytes, flush: true);
      AppLogger.debug('EncryptionService: encrypted ${sourceFile.path} -> ${targetFile.path} (${encryptedBytes.length} bytes)');
      return targetFile;
    } catch (e, st) {
      AppLogger.error('EncryptionService.encryptFile failed', e, st);
      rethrow;
    }
  }

  /// Decrypts [encryptedFile] and returns raw decrypted bytes in memory.
  Future<Uint8List> decryptFile({
    required File encryptedFile,
    required String base64Key,
  }) async {
    try {
      if (!await encryptedFile.exists()) {
        throw FileSystemException('Encrypted file does not exist', encryptedFile.path);
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      return decryptBytes(encryptedBytes, base64Key);
    } catch (e, st) {
      AppLogger.error('EncryptionService.decryptFile failed', e, st);
      rethrow;
    }
  }
}
