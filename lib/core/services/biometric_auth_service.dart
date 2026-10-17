import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/logger.dart';

/// Service wrapping [LocalAuthentication] to handle hardware biometric checks,
/// device capability discovery, and secure biometric / device credential authentication.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Checks if hardware biometrics can be checked on this device.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e, st) {
      AppLogger.error('BiometricAuthService: canCheckBiometrics failed', e, st);
      return false;
    }
  }

  /// Checks if the device supports biometric or hardware credential authentication.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e, st) {
      AppLogger.error('BiometricAuthService: isDeviceSupported failed', e, st);
      return false;
    }
  }

  /// Checks whether biometrics or device credentials can be used for authentication.
  Future<bool> isBiometricsAvailable() async {
    final supported = await isDeviceSupported();
    if (!supported) return false;

    final canCheck = await canCheckBiometrics();
    if (canCheck) return true;

    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  /// Discovers enrolled biometric modalities (Face ID, Fingerprint, Iris, etc.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e, st) {
      AppLogger.error(
          'BiometricAuthService: getAvailableBiometrics failed', e, st);
      return const [];
    }
  }

  /// Returns `true` if at least one biometric modality is actively enrolled.
  Future<bool> hasEnrolledBiometrics() async {
    final list = await getAvailableBiometrics();
    return list.isNotEmpty;
  }

  /// Prompts the user with system biometric authentication (Face ID / Touch ID / Fingerprint)
  /// or device PIN/Passcode fallback when [biometricOnly] is `false`.
  ///
  /// Returns `true` on successful verification, `false` on cancel, failure, or platform error.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) {
        AppLogger.warn(
            'BiometricAuthService: Biometrics/Credentials not available on device');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      AppLogger.info(
          'BiometricAuthService: authentication result = $authenticated');
      return authenticated;
    } on PlatformException catch (e, st) {
      AppLogger.error('BiometricAuthService: authentication failed', e, st);
      return false;
    } catch (e, st) {
      AppLogger.error(
          'BiometricAuthService: unexpected authentication error', e, st);
      return false;
    }
  }

  /// Cancels an active authentication prompt if one is in progress.
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } on PlatformException catch (e, st) {
      AppLogger.error(
          'BiometricAuthService: stopAuthentication failed', e, st);
      return false;
    }
  }
}
