import 'dart:async';
import 'package:flutter/widgets.dart';
import '../utils/logger.dart';
import 'biometric_auth_service.dart';

/// Global session manager that coordinates biometric unlock states across the application.
///
/// Features:
/// - Tracks global `isUnlocked` status for accessing protected folders and notes.
/// - Prompts Face ID / Touch ID / Fingerprint / Device PIN authentication via [BiometricAuthService].
/// - Emits real-time reactive updates through [ChangeNotifier] and a broadcast stream.
/// - Supports auto-lock on app backgrounding and configurable inactivity timeouts.
class SessionManager extends ChangeNotifier with WidgetsBindingObserver {
  SessionManager({
    required BiometricAuthService authService,
    this.lockOnAppBackground = true,
    this.autoLockTimeout,
    bool registerLifecycleObserver = true,
  }) : _authService = authService {
    if (registerLifecycleObserver) {
      try {
        WidgetsBinding.instance.addObserver(this);
      } catch (_) {
        // WidgetsBinding may not be available in headless unit tests
      }
    }
  }

  final BiometricAuthService _authService;

  /// Whether the session should automatically re-lock when the app is paused/backgrounded.
  final bool lockOnAppBackground;

  /// Optional duration after which an unlocked session expires.
  final Duration? autoLockTimeout;

  bool _isUnlocked = false;
  DateTime? _lastUnlockedAt;

  final StreamController<bool> _unlockStateController =
      StreamController<bool>.broadcast();

  /// Whether protected content is currently unlocked in this app session.
  bool get isUnlocked {
    if (_isUnlocked && autoLockTimeout != null && _lastUnlockedAt != null) {
      if (DateTime.now().difference(_lastUnlockedAt!) > autoLockTimeout!) {
        _isUnlocked = false;
        _lastUnlockedAt = null;
        notifyListeners();
        _unlockStateController.add(false);
      }
    }
    return _isUnlocked;
  }

  /// Timestamp of the last successful biometric unlock.
  DateTime? get lastUnlockedAt => _lastUnlockedAt;

  /// Stream of unlock state changes (`true` = unlocked, `false` = locked).
  Stream<bool> get onUnlockStateChanged => _unlockStateController.stream;

  /// Authenticates using biometrics (or device credentials fallback) and unlocks the session on success.
  Future<bool> authenticateAndUnlock({
    String localizedReason = 'Unlock protected folders and notes',
    bool biometricOnly = false,
  }) async {
    try {
      final success = await _authService.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
      );

      if (success) {
        _isUnlocked = true;
        _lastUnlockedAt = DateTime.now();
        notifyListeners();
        _unlockStateController.add(true);
        AppLogger.info('SessionManager: session unlocked successfully');
        return true;
      }

      AppLogger.warn('SessionManager: authentication failed or was cancelled');
      return false;
    } catch (e, st) {
      AppLogger.error('SessionManager: error during unlock authentication', e, st);
      return false;
    }
  }

  /// Explicitly locks the session, concealing protected folders and notes.
  void lock() {
    if (_isUnlocked) {
      _isUnlocked = false;
      _lastUnlockedAt = null;
      notifyListeners();
      _unlockStateController.add(false);
      AppLogger.info('SessionManager: session locked');
    }
  }

  /// Programmatically unlocks the session without a system biometric prompt (e.g. for unit testing).
  void unlockWithoutPrompt() {
    _isUnlocked = true;
    _lastUnlockedAt = DateTime.now();
    notifyListeners();
    _unlockStateController.add(true);
    AppLogger.info('SessionManager: unlocked without prompt');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (lockOnAppBackground &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached ||
            state == AppLifecycleState.hidden)) {
      AppLogger.debug('SessionManager: app backgrounded, locking session');
      lock();
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _unlockStateController.close();
    super.dispose();
  }
}
