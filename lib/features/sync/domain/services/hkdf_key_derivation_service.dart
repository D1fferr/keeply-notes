import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../../../core/constants/app_constants.dart';

/// RFC 5869 compliant HMAC-based Extract-and-Expand Key Derivation Function (HKDF)
/// using the SHA-256 cryptographic hash function.
class HkdfSha256 {
  HkdfSha256._();

  /// SHA-256 digest output length in bytes.
  static const int hashLen = 32;

  /// Step 1: HKDF-Extract(salt, IKM) -> PRK
  ///
  /// Extracts a pseudorandom key [PRK] of length [hashLen] (32 bytes) from
  /// input keying material [ikm] and optional [salt].
  /// If [salt] is null or empty, a string of 32 zeros is used as per RFC 5869.
  static List<int> extract({
    required List<int> ikm,
    List<int>? salt,
  }) {
    final effectiveSalt = (salt == null || salt.isEmpty)
        ? List<int>.filled(hashLen, 0)
        : salt;

    final hmac = Hmac(sha256, effectiveSalt);
    return hmac.convert(ikm).bytes;
  }

  /// Step 2: HKDF-Expand(PRK, info, L) -> OKM
  ///
  /// Expands pseudorandom key [prk] of length at least [hashLen] to an output
  /// keying material (OKM) of [lengthBytes].
  static Uint8List expand({
    required List<int> prk,
    List<int>? info,
    int lengthBytes = 32,
  }) {
    if (lengthBytes <= 0 || lengthBytes > 255 * hashLen) {
      throw ArgumentError.value(
        lengthBytes,
        'lengthBytes',
        'Output length must be between 1 and ${255 * hashLen} bytes',
      );
    }

    final contextInfo = info ?? const <int>[];
    final numBlocks = (lengthBytes / hashLen).ceil();
    final okm = BytesBuilder(copy: false);
    List<int> previousBlock = const <int>[];

    for (var i = 1; i <= numBlocks; i++) {
      final hmac = Hmac(sha256, prk);
      final blockInput = <int>[
        ...previousBlock,
        ...contextInfo,
        i,
      ];
      previousBlock = hmac.convert(blockInput).bytes;
      okm.add(previousBlock);
    }

    return Uint8List.fromList(okm.toBytes().sublist(0, lengthBytes));
  }

  /// Full HKDF (Extract and Expand): Derives [lengthBytes] of output keying material
  /// from [ikm] using [salt] and optional application context [info].
  static Uint8List derive({
    required List<int> ikm,
    List<int>? salt,
    List<int>? info,
    int lengthBytes = 32,
  }) {
    final prk = extract(ikm: ikm, salt: salt);
    return expand(prk: prk, info: info, lengthBytes: lengthBytes);
  }
}

/// Deterministic Key Derivation Engine for End-to-End Encrypted Cloud Sync.
///
/// Implements specification 4.D:
/// - Zero user friction: No master passwords or manual PINs required from user.
/// - Deterministic: `HKDF-SHA256(Google_User_ID + App_Salt)`.
/// - Logging into the same Google Account on any device deterministically derives
///   the identical 256-bit (32-byte) AES-256-GCM encryption key.
class SyncKeyDerivationEngine {
  const SyncKeyDerivationEngine({
    String? defaultSalt,
    String? defaultInfo,
  })  : _defaultSalt = defaultSalt ?? AppConstants.syncSalt,
        _defaultInfo = defaultInfo ?? 'keeply-notes-e2ee-sync-key-v1';

  final String _defaultSalt;
  final String _defaultInfo;

  /// Required AES-256 key length: 32 bytes (256 bits).
  static const int keyLength = 32;

  /// Derives a 32-byte (256-bit) [Uint8List] AES-256-GCM key from [googleUserId].
  Uint8List deriveKey(
    String googleUserId, {
    String? customSalt,
    String? customInfo,
  }) {
    final trimmedId = googleUserId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Google User ID cannot be empty');
    }

    final ikm = utf8.encode(trimmedId);
    final salt = utf8.encode(customSalt ?? _defaultSalt);
    final info = utf8.encode(customInfo ?? _defaultInfo);

    return HkdfSha256.derive(
      ikm: ikm,
      salt: salt,
      info: info,
      lengthBytes: keyLength,
    );
  }

  /// Derives a Base64-encoded string representation of the 256-bit key.
  String deriveBase64Key(
    String googleUserId, {
    String? customSalt,
    String? customInfo,
  }) {
    final keyBytes = deriveKey(
      googleUserId,
      customSalt: customSalt,
      customInfo: customInfo,
    );
    return base64.encode(keyBytes);
  }
}
