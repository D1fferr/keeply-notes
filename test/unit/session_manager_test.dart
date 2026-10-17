import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/services/biometric_auth_service.dart';
import 'package:keeply_notes/core/services/session_manager.dart';

class MockBiometricAuthService extends Fake implements BiometricAuthService {
  bool shouldSucceed = true;
  bool shouldThrow = false;
  int authCallCount = 0;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    authCallCount++;
    if (shouldThrow) {
      throw Exception('Biometric hardware error');
    }
    return shouldSucceed;
  }
}

void main() {
  group('SessionManager Unit Tests (Task 5.1)', () {
    late MockBiometricAuthService mockAuth;
    late SessionManager sessionManager;

    setUp(() {
      mockAuth = MockBiometricAuthService();
      sessionManager = SessionManager(
        authService: mockAuth,
        registerLifecycleObserver: false,
      );
    });

    tearDown(() {
      sessionManager.dispose();
    });

    test('initial state is locked with null lastUnlockedAt', () {
      expect(sessionManager.isUnlocked, isFalse);
      expect(sessionManager.lastUnlockedAt, isNull);
    });

    test('authenticateAndUnlock updates state, notifies listeners, and emits on stream', () async {
      mockAuth.shouldSucceed = true;

      var listenerNotified = false;
      sessionManager.addListener(() {
        listenerNotified = true;
      });

      final streamEvents = <bool>[];
      final subscription = sessionManager.onUnlockStateChanged.listen(streamEvents.add);

      final result = await sessionManager.authenticateAndUnlock(
        localizedReason: 'Test unlock',
      );

      expect(result, isTrue);
      expect(sessionManager.isUnlocked, isTrue);
      expect(sessionManager.lastUnlockedAt, isNotNull);
      expect(listenerNotified, isTrue);
      expect(mockAuth.authCallCount, equals(1));

      // Wait a tick for stream emission
      await Future<void>.delayed(Duration.zero);
      expect(streamEvents, equals([true]));

      await subscription.cancel();
    });

    test('authenticateAndUnlock remains locked on failed authentication', () async {
      mockAuth.shouldSucceed = false;

      var listenerNotified = false;
      sessionManager.addListener(() {
        listenerNotified = true;
      });

      final result = await sessionManager.authenticateAndUnlock();

      expect(result, isFalse);
      expect(sessionManager.isUnlocked, isFalse);
      expect(sessionManager.lastUnlockedAt, isNull);
      expect(listenerNotified, isFalse);
    });

    test('authenticateAndUnlock handles exceptions gracefully without crashing', () async {
      mockAuth.shouldThrow = true;

      final result = await sessionManager.authenticateAndUnlock();

      expect(result, isFalse);
      expect(sessionManager.isUnlocked, isFalse);
    });

    test('lock resets unlock state and timestamp and emits false', () async {
      sessionManager.unlockWithoutPrompt();
      expect(sessionManager.isUnlocked, isTrue);
      expect(sessionManager.lastUnlockedAt, isNotNull);

      var listenerNotified = false;
      sessionManager.addListener(() {
        listenerNotified = true;
      });

      final streamEvents = <bool>[];
      final subscription = sessionManager.onUnlockStateChanged.listen(streamEvents.add);

      sessionManager.lock();

      expect(sessionManager.isUnlocked, isFalse);
      expect(sessionManager.lastUnlockedAt, isNull);
      expect(listenerNotified, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(streamEvents, equals([false]));

      // Subsequent lock call does nothing if already locked
      listenerNotified = false;
      sessionManager.lock();
      expect(listenerNotified, isFalse);

      await subscription.cancel();
    });

    test('unlockWithoutPrompt unlocks without invoking BiometricAuthService', () async {
      final streamEvents = <bool>[];
      final subscription = sessionManager.onUnlockStateChanged.listen(streamEvents.add);

      sessionManager.unlockWithoutPrompt();

      expect(sessionManager.isUnlocked, isTrue);
      expect(sessionManager.lastUnlockedAt, isNotNull);
      expect(mockAuth.authCallCount, equals(0));

      await Future<void>.delayed(Duration.zero);
      expect(streamEvents, equals([true]));

      await subscription.cancel();
    });

    test('lifecycle backgrounding locks session when lockOnAppBackground is true', () {
      sessionManager.unlockWithoutPrompt();
      expect(sessionManager.isUnlocked, isTrue);

      // App paused -> should lock
      sessionManager.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(sessionManager.isUnlocked, isFalse);

      sessionManager.unlockWithoutPrompt();
      expect(sessionManager.isUnlocked, isTrue);

      // App hidden -> should lock
      sessionManager.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(sessionManager.isUnlocked, isFalse);

      sessionManager.unlockWithoutPrompt();
      expect(sessionManager.isUnlocked, isTrue);

      // App detached -> should lock
      sessionManager.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(sessionManager.isUnlocked, isFalse);

      sessionManager.unlockWithoutPrompt();
      expect(sessionManager.isUnlocked, isTrue);

      // App resumed -> should NOT lock
      sessionManager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(sessionManager.isUnlocked, isTrue);
    });

    test('lifecycle backgrounding ignores backgrounding when lockOnAppBackground is false', () {
      final customManager = SessionManager(
        authService: mockAuth,
        lockOnAppBackground: false,
        registerLifecycleObserver: false,
      );

      customManager.unlockWithoutPrompt();
      expect(customManager.isUnlocked, isTrue);

      customManager.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(customManager.isUnlocked, isTrue);

      customManager.dispose();
    });

    test('autoLockTimeout automatically expires unlock state after specified duration', () async {
      final timedManager = SessionManager(
        authService: mockAuth,
        autoLockTimeout: const Duration(milliseconds: 50),
        registerLifecycleObserver: false,
      );

      timedManager.unlockWithoutPrompt();
      expect(timedManager.isUnlocked, isTrue);

      // Wait past auto-lock timeout
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(timedManager.isUnlocked, isFalse);
      expect(timedManager.lastUnlockedAt, isNull);

      timedManager.dispose();
    });
  });
}
