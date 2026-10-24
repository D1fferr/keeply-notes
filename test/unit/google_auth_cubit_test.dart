import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:keeply_notes/features/sync/domain/entities/google_user_entity.dart';
import 'package:keeply_notes/features/sync/domain/repositories/google_auth_repository.dart';
import 'package:keeply_notes/features/sync/presentation/cubit/google_auth_cubit.dart';
import 'package:keeply_notes/features/sync/presentation/cubit/google_auth_state.dart';

class FakeGoogleAuthRepository implements GoogleAuthRepository {
  GoogleUserEntity? mockUser;
  final StreamController<GoogleUserEntity?> _controller =
      StreamController<GoogleUserEntity?>.broadcast();

  bool signInThrows = false;
  bool silentSignInThrows = false;
  bool signOutThrows = false;
  bool disconnectThrows = false;
  bool clearCacheCalled = false;
  bool getAuthHeadersCalled = false;

  @override
  Stream<GoogleUserEntity?> get authStateChanges => _controller.stream;

  @override
  GoogleUserEntity? get currentUser => mockUser;

  @override
  bool get isSignedIn => mockUser != null;

  @override
  Future<GoogleUserEntity?> signIn() async {
    if (signInThrows) throw Exception('Google Sign-In failed');
    _controller.add(mockUser);
    return mockUser;
  }

  @override
  Future<GoogleUserEntity?> signInSilently() async {
    if (silentSignInThrows) throw Exception('Silent sign in failed');
    _controller.add(mockUser);
    return mockUser;
  }

  @override
  Future<void> signOut() async {
    if (signOutThrows) throw Exception('Sign out failed');
    mockUser = null;
    _controller.add(null);
  }

  @override
  Future<void> disconnect() async {
    if (disconnectThrows) throw Exception('Disconnect failed');
    mockUser = null;
    _controller.add(null);
  }

  @override
  Future<void> clearAuthCache() async {
    clearCacheCalled = true;
  }

  @override
  Future<Map<String, String>> getAuthHeaders({bool forceRefresh = false}) async {
    getAuthHeadersCalled = true;
    return {'Authorization': 'Bearer test-token'};
  }

  @override
  drive.DriveApi? getDriveApi() => null;
}

void main() {
  group('GoogleAuthCubit Tests (Task 6.1)', () {
    late FakeGoogleAuthRepository repository;
    late GoogleUserEntity testUser;

    setUp(() {
      repository = FakeGoogleAuthRepository();
      testUser = const GoogleUserEntity(
        id: 'usr-444',
        email: 'bob@example.com',
        displayName: 'Bob The Builder',
        photoUrl: 'https://example.com/bob.jpg',
      );
    });

    test('starts with GoogleAuthInitial when autoInitialize is false', () {
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      expect(cubit.state, isA<GoogleAuthInitial>());
      expect(cubit.isSignedIn, isFalse);
      cubit.dispose();
    });

    test('init restores authenticated session silently when account exists', () async {
      repository.mockUser = testUser;

      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state, isA<GoogleAuthAuthenticated>());
      final authState = cubit.state as GoogleAuthAuthenticated;
      expect(authState.user.email, 'bob@example.com');
      expect(cubit.currentUser, equals(testUser));
      expect(cubit.isSignedIn, isTrue);

      cubit.dispose();
    });

    test('init falls back to unauthenticated when silent sign in yields no account', () async {
      repository.mockUser = null;

      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state, isA<GoogleAuthUnauthenticated>());
      expect(cubit.isSignedIn, isFalse);

      cubit.dispose();
    });

    test('interactive signIn transitions to authenticated on success', () async {
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      repository.mockUser = testUser;

      final success = await cubit.signIn();

      expect(success, isTrue);
      expect(cubit.state, isA<GoogleAuthAuthenticated>());
      final authState = cubit.state as GoogleAuthAuthenticated;
      expect(authState.user.id, 'usr-444');

      cubit.dispose();
    });

    test('interactive signIn returns false and sets unauthenticated on user cancel', () async {
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      repository.mockUser = null; // User cancelled

      final success = await cubit.signIn();

      expect(success, isFalse);
      expect(cubit.state, isA<GoogleAuthUnauthenticated>());

      cubit.dispose();
    });

    test('interactive signIn emits GoogleAuthError on exception', () async {
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      repository.signInThrows = true;

      final success = await cubit.signIn();

      expect(success, isFalse);
      expect(cubit.state, isA<GoogleAuthError>());
      final errorState = cubit.state as GoogleAuthError;
      expect(errorState.message, contains('Google Sign-In failed'));

      cubit.dispose();
    });

    test('signOut transitions to GoogleAuthUnauthenticated', () async {
      repository.mockUser = testUser;
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      await cubit.signIn();
      expect(cubit.state, isA<GoogleAuthAuthenticated>());

      await cubit.signOut();
      expect(cubit.state, isA<GoogleAuthUnauthenticated>());
      expect(cubit.isSignedIn, isFalse);

      cubit.dispose();
    });

    test('disconnect transitions to GoogleAuthUnauthenticated', () async {
      repository.mockUser = testUser;
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      await cubit.signIn();
      await cubit.disconnect();

      expect(cubit.state, isA<GoogleAuthUnauthenticated>());
      expect(cubit.isSignedIn, isFalse);

      cubit.dispose();
    });

    test('refreshTokens calls clearAuthCache and getAuthHeaders', () async {
      final cubit = GoogleAuthCubit(
        authRepository: repository,
        autoInitialize: false,
      );

      await cubit.refreshTokens();

      expect(repository.clearCacheCalled, isTrue);
      expect(repository.getAuthHeadersCalled, isTrue);

      cubit.dispose();
    });
  });
}
