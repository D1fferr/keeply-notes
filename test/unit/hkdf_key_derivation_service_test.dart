import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/constants/app_constants.dart';
import 'package:keeply_notes/features/sync/domain/services/hkdf_key_derivation_service.dart';

void main() {
  group('HkdfSha256 & RFC 5869 Compliance Tests (Task 6.2)', () {
    test('RFC 5869 Test Case 1 verification (SHA-256)', () {
      // IKM: 22 octets of 0x0b
      final ikm = List<int>.filled(22, 0x0b);
      // Salt: 13 octets 0x000102030405060708090a0b0c
      final salt = [
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
      ];
      // Info: 10 octets 0xf0f1f2f3f4f5f6f7f8f9
      final info = [
        0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9
      ];
      const int l = 42;

      final prk = HkdfSha256.extract(ikm: ikm, salt: salt);
      final expectedPrkHex =
          '077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e0';
      final actualPrkHex = prk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(actualPrkHex, expectedPrkHex);

      final okm = HkdfSha256.expand(prk: prk, info: info, lengthBytes: l);
      final expectedOkmHex =
          '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865';
      final actualOkmHex = okm.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(actualOkmHex, expectedOkmHex);

      final fullOkm = HkdfSha256.derive(
        ikm: ikm,
        salt: salt,
        info: info,
        lengthBytes: l,
      );
      expect(fullOkm, equals(okm));
    });

    test('RFC 5869 Test Case 3 (Zero salt default)', () {
      final ikm = List<int>.filled(22, 0x0b);
      // Empty salt should default to 32 zeros
      final prkWithNullSalt = HkdfSha256.extract(ikm: ikm, salt: null);
      final prkWithEmptySalt = HkdfSha256.extract(ikm: ikm, salt: const []);
      final prkWithExplicitZeros =
          HkdfSha256.extract(ikm: ikm, salt: List<int>.filled(32, 0));

      expect(prkWithNullSalt, equals(prkWithExplicitZeros));
      expect(prkWithEmptySalt, equals(prkWithExplicitZeros));
    });

    test('rejects invalid expand output lengths', () {
      final prk = List<int>.filled(32, 1);
      expect(() => HkdfSha256.expand(prk: prk, lengthBytes: 0), throwsArgumentError);
      expect(() => HkdfSha256.expand(prk: prk, lengthBytes: -5), throwsArgumentError);
      expect(
        () => HkdfSha256.expand(prk: prk, lengthBytes: 255 * 32 + 1),
        throwsArgumentError,
      );
    });
  });

  group('SyncKeyDerivationEngine Unit Tests (Task 6.2)', () {
    const engine = SyncKeyDerivationEngine();

    test('deterministic derivation: same user ID produces identical key', () {
      const googleUserId = '109847293847291039847';

      final key1 = engine.deriveKey(googleUserId);
      final key2 = engine.deriveKey(googleUserId);

      expect(key1.length, 32);
      expect(key2.length, 32);
      expect(key1, equals(key2));

      final b64Key1 = engine.deriveBase64Key(googleUserId);
      final b64Key2 = engine.deriveBase64Key(googleUserId);
      expect(b64Key1, equals(b64Key2));
      expect(base64.decode(b64Key1), equals(key1));
    });

    test('different user IDs produce different keys', () {
      final keyUserA = engine.deriveKey('user_alpha_111');
      final keyUserB = engine.deriveKey('user_beta_222');

      expect(keyUserA, isNot(equals(keyUserB)));
    });

    test('custom salt and info produce isolated keys', () {
      const userId = 'user_constant';

      final keyDefault = engine.deriveKey(userId);
      final keyCustomSalt = engine.deriveKey(userId, customSalt: 'alternate_salt_456');
      final keyCustomInfo = engine.deriveKey(userId, customInfo: 'alternate_context');

      expect(keyDefault, isNot(equals(keyCustomSalt)));
      expect(keyDefault, isNot(equals(keyCustomInfo)));
    });

    test('uses AppConstants.syncSalt as default salt', () {
      const userId = 'user_test_salt';

      final keyImplicit = engine.deriveKey(userId);
      final keyExplicit = engine.deriveKey(userId, customSalt: AppConstants.syncSalt);

      expect(keyImplicit, equals(keyExplicit));
    });

    test('throws ArgumentError on empty or whitespace user ID', () {
      expect(() => engine.deriveKey(''), throwsArgumentError);
      expect(() => engine.deriveKey('   '), throwsArgumentError);
      expect(() => engine.deriveBase64Key(''), throwsArgumentError);
    });
  });
}
