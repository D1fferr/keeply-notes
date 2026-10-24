import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import '../../../../core/utils/logger.dart';

/// Exception thrown when AES-GCM decryption or authentication tag verification fails.
class SyncDecryptionException implements Exception {
  const SyncDecryptionException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'SyncDecryptionException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Service providing authenticated AES-256-GCM encryption and decryption
/// for item-level cloud sync payloads (notes, folders, attachments).
///
/// Payload binary wire format:
/// [12-byte IV / Nonce] + [AES-256-GCM Ciphertext with 16-byte Auth Tag]
class SyncEncryptionService {
  const SyncEncryptionService();

  /// Standard NIST SP 800-38D recommended IV size for AES-GCM (96 bits).
  static const int ivLength = 12;

  /// Required AES-256 key length (256 bits).
  static const int keyLength = 32;

  /// Standard GCM Authentication Tag length (128 bits).
  static const int tagLength = 16;

  /// Minimum valid payload size: 12 bytes IV + 16 bytes Tag = 28 bytes.
  static const int minPayloadLength = ivLength + tagLength;

  /// Validates that [key] has an exact length of 32 bytes (256 bits).
  enc.Key _validateKey(Uint8List key) {
    if (key.length != keyLength) {
      throw ArgumentError(
        'Invalid key length: expected $keyLength bytes (256 bits), got ${key.length}',
      );
    }
    return enc.Key(key);
  }

  /// Encrypts raw [plainBytes] using AES-256-GCM and prepends the random 12-byte IV.
  Uint8List encryptPayload({
    required Uint8List plainBytes,
    required Uint8List key,
    Uint8List? customIv,
  }) {
    final encKey = _validateKey(key);
    final enc.IV iv;
    if (customIv != null) {
      if (customIv.length != ivLength) {
        throw ArgumentError(
          'Custom IV must be $ivLength bytes, got ${customIv.length}',
        );
      }
      iv = enc.IV(customIv);
    } else {
      iv = enc.IV.fromSecureRandom(ivLength);
    }

    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setRange(0, iv.bytes.length, iv.bytes);
    combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

    return combined;
  }

  /// Decrypts [encryptedPayload] extracting the 12-byte IV and validating the GCM authentication tag.
  Uint8List decryptPayload({
    required Uint8List encryptedPayload,
    required Uint8List key,
  }) {
    if (encryptedPayload.length < minPayloadLength) {
      throw SyncDecryptionException(
        'Encrypted payload is too short: expected at least $minPayloadLength bytes, got ${encryptedPayload.length}',
      );
    }

    final encKey = _validateKey(key);
    final ivBytes = encryptedPayload.sublist(0, ivLength);
    final cipherWithTagBytes = encryptedPayload.sublist(ivLength);

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.gcm));

    try {
      final decryptedList = encrypter.decryptBytes(
        enc.Encrypted(cipherWithTagBytes),
        iv: iv,
      );
      return Uint8List.fromList(decryptedList);
    } catch (e, st) {
      AppLogger.error('SyncEncryptionService: GCM payload decryption failed', e, st);
      throw SyncDecryptionException(
        'Authentication tag verification failed or payload corrupted',
        e,
      );
    }
  }

  /// Encrypts a JSON-serializable Map into an encrypted byte array.
  Uint8List encryptJson({
    required Map<String, dynamic> jsonMap,
    required Uint8List key,
    Uint8List? customIv,
  }) {
    final jsonString = jsonEncode(jsonMap);
    final plainBytes = Uint8List.fromList(utf8.encode(jsonString));
    return encryptPayload(plainBytes: plainBytes, key: key, customIv: customIv);
  }

  /// Decrypts an encrypted byte array into a JSON Map.
  Map<String, dynamic> decryptJson({
    required Uint8List encryptedPayload,
    required Uint8List key,
  }) {
    final plainBytes = decryptPayload(encryptedPayload: encryptedPayload, key: key);
    final jsonString = utf8.decode(plainBytes);
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Decrypted payload does not contain a valid JSON map');
    }
    return decoded;
  }

  /// Encrypts a plain text string into an encrypted byte array.
  Uint8List encryptString({
    required String plainText,
    required Uint8List key,
    Uint8List? customIv,
  }) {
    final plainBytes = Uint8List.fromList(utf8.encode(plainText));
    return encryptPayload(plainBytes: plainBytes, key: key, customIv: customIv);
  }

  /// Decrypts an encrypted byte array into a plain text string.
  String decryptString({
    required Uint8List encryptedPayload,
    required Uint8List key,
  }) {
    final plainBytes = decryptPayload(encryptedPayload: encryptedPayload, key: key);
    return utf8.decode(plainBytes);
  }

  /// Encrypts [sourceFile] into [targetFile] using AES-256-GCM.
  Future<File> encryptFile({
    required File sourceFile,
    required File targetFile,
    required Uint8List key,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final encryptedBytes = encryptPayload(plainBytes: bytes, key: key);

      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      await targetFile.writeAsBytes(encryptedBytes, flush: true);
      AppLogger.debug('SyncEncryptionService: encrypted ${sourceFile.path} -> ${targetFile.path}');
      return targetFile;
    } catch (e, st) {
      AppLogger.error('SyncEncryptionService.encryptFile failed', e, st);
      rethrow;
    }
  }

  /// Decrypts [encryptedFile] and returns the raw decrypted bytes in memory.
  Future<Uint8List> decryptFile({
    required File encryptedFile,
    required Uint8List key,
  }) async {
    try {
      if (!await encryptedFile.exists()) {
        throw FileSystemException('Encrypted file does not exist', encryptedFile.path);
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      return decryptPayload(encryptedPayload: encryptedBytes, key: key);
    } catch (e, st) {
      AppLogger.error('SyncEncryptionService.decryptFile failed', e, st);
      rethrow;
    }
  }
}
