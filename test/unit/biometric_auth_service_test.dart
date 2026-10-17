import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/services/biometric_auth_service.dart';
import 'package:local_auth/local_auth.dart';

class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  bool canCheck = true;
  bool deviceSupported = true;
  List<BiometricType> biometrics = [
    BiometricType.fingerprint,
    BiometricType.face,
  ];
  bool authResult = true;
  bool stopResult = true;
  Object? errorToThrow;

  @override
  Future<bool> get canCheckBiometrics async {
    if (errorToThrow != null) throw errorToThrow!;
    return canCheck;
  }

  @override
  Future<bool> isDeviceSupported() async {
    if (errorToThrow != null) throw errorToThrow!;
    return deviceSupported;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (errorToThrow != null) throw errorToThrow!;
    return biometrics;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return authResult;
  }

  @override
  Future<bool> stopAuthentication() async {
    if (errorToThrow != null) throw errorToThrow!;
    return stopResult;
  }
}

void main() {
  group('BiometricAuthService Unit Tests (Task 5.1)', () {
    late FakeLocalAuthentication fakeAuth;
    late BiometricAuthService service;

    setUp(() {
      fakeAuth = FakeLocalAuthentication();
      service = BiometricAuthService(localAuth: fakeAuth);
    });

    test('canCheckBiometrics returns correct status and handles platform error', () async {
      fakeAuth.canCheck = true;
      expect(await service.canCheckBiometrics(), isTrue);

      fakeAuth.canCheck = false;
      expect(await service.canCheckBiometrics(), isFalse);

      fakeAuth.errorToThrow = PlatformException(code: 'NotAvailable');
      expect(await service.canCheckBiometrics(), isFalse);
    });

    test('isDeviceSupported returns correct status and handles platform error', () async {
      fakeAuth.deviceSupported = true;
      expect(await service.isDeviceSupported(), isTrue);

      fakeAuth.deviceSupported = false;
      expect(await service.isDeviceSupported(), isFalse);

      fakeAuth.errorToThrow = PlatformException(code: 'HardwareUnavailable');
      expect(await service.isDeviceSupported(), isFalse);
    });

    test('isBiometricsAvailable verifies device support and hardware readiness', () async {
      // 1. Device not supported
      fakeAuth.deviceSupported = false;
      expect(await service.isBiometricsAvailable(), isFalse);

      // 2. Device supported and canCheckBiometrics is true
      fakeAuth.deviceSupported = true;
      fakeAuth.canCheck = true;
      expect(await service.isBiometricsAvailable(), isTrue);

      // 3. canCheckBiometrics is false, but biometrics list is not empty
      fakeAuth.canCheck = false;
      fakeAuth.biometrics = [BiometricType.fingerprint];
      expect(await service.isBiometricsAvailable(), isTrue);

      // 4. canCheckBiometrics is false and biometrics list is empty
      fakeAuth.biometrics = [];
      expect(await service.isBiometricsAvailable(), isFalse);
    });

    test('getAvailableBiometrics and hasEnrolledBiometrics identify modalities', () async {
      fakeAuth.biometrics = [BiometricType.face, BiometricType.fingerprint];
      final available = await service.getAvailableBiometrics();
      expect(available, containsAll([BiometricType.face, BiometricType.fingerprint]));
      expect(await service.hasEnrolledBiometrics(), isTrue);

      fakeAuth.biometrics = [];
      final empty = await service.getAvailableBiometrics();
      expect(empty, isEmpty);
      expect(await service.hasEnrolledBiometrics(), isFalse);

      fakeAuth.errorToThrow = PlatformException(code: 'PasscodeNotSet');
      final errorResult = await service.getAvailableBiometrics();
      expect(errorResult, isEmpty);
      expect(await service.hasEnrolledBiometrics(), isFalse);
    });

    test('authenticate handles successful verification and failure', () async {
      fakeAuth.deviceSupported = true;
      fakeAuth.canCheck = true;
      fakeAuth.authResult = true;

      final success = await service.authenticate(
        localizedReason: 'Unlock test',
      );
      expect(success, isTrue);

      fakeAuth.authResult = false;
      final failed = await service.authenticate(
        localizedReason: 'Unlock test',
      );
      expect(failed, isFalse);
    });

    test('authenticate returns false when biometrics are unavailable on device', () async {
      fakeAuth.deviceSupported = false;

      final result = await service.authenticate(
        localizedReason: 'Unlock test',
      );
      expect(result, isFalse);
    });

    test('authenticate catches PlatformException and unexpected errors gracefully', () async {
      fakeAuth.deviceSupported = true;
      fakeAuth.canCheck = true;
      fakeAuth.errorToThrow = PlatformException(code: 'LockedOut');

      final resultPlatform = await service.authenticate(
        localizedReason: 'Unlock test',
      );
      expect(resultPlatform, isFalse);

      fakeAuth.errorToThrow = Exception('Unknown crash');
      final resultGeneric = await service.authenticate(
        localizedReason: 'Unlock test',
      );
      expect(resultGeneric, isFalse);
    });

    test('stopAuthentication calls underlying localAuth and handles exceptions', () async {
      fakeAuth.stopResult = true;
      expect(await service.stopAuthentication(), isTrue);

      fakeAuth.errorToThrow = PlatformException(code: 'Failed');
      expect(await service.stopAuthentication(), isFalse);
    });
  });
}
