import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:keeply_notes/core/services/google_auth_service.dart';
import 'package:keeply_notes/features/sync/data/repositories/google_auth_repository_impl.dart';
import 'package:keeply_notes/features/sync/domain/entities/google_user_entity.dart';
import 'package:keeply_notes/features/sync/domain/repositories/google_auth_repository.dart';

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  FakeGoogleSignInAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.serverAuthCode,
    Map<String, String>? authHeaders,
  }) : _authHeaders = authHeaders ?? {'Authorization': 'Bearer test-token'};

  @override
  final String id;

  @override
  final String email;

  @override
  final String? displayName;

  @override
  final String? photoUrl;

  @override
  final String? serverAuthCode;

  final Map<String, String> _authHeaders;

  @override
  Future<Map<String, String>> get authHeaders async => _authHeaders;

  @override
  Future<void> clearAuthCache() async {}
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  FakeGoogleSignInAccount? mockAccount;
  final StreamController<GoogleSignInAccount?> _userController =
      StreamController<GoogleSignInAccount?>.broadcast();

  @override
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _userController.stream;

  @override
  GoogleSignInAccount? get currentUser => mockAccount;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    _userController.add(mockAccount);
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool reAuthenticate = false,
    bool suppressErrors = true,
  }) async {
    _userController.add(mockAccount);
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    mockAccount = null;
    _userController.add(null);
    return null;
  }

  @override
  Future<GoogleSignInAccount?> disconnect() async {
    mockAccount = null;
    _userController.add(null);
    return null;
  }
}

void main() {
  group('GoogleUserEntity & GoogleAuthRepositoryImpl Tests (Task 6.1)', () {
    late FakeGoogleSignIn fakeSignIn;
    late GoogleAuthService authService;
    late GoogleAuthRepository repository;
    late FakeGoogleSignInAccount mockAccount;

    setUp(() {
      fakeSignIn = FakeGoogleSignIn();
      mockAccount = FakeGoogleSignInAccount(
        id: 'usr-123456789',
        email: 'alice@example.com',
        displayName: 'Alice Cooper',
        photoUrl: 'https://avatar.example.com/alice.jpg',
      );
      authService = GoogleAuthService(googleSignIn: fakeSignIn);
      repository = GoogleAuthRepositoryImpl(authService);
    });

    test('GoogleUserEntity properties, equality, and copyWith', () {
      final user1 = GoogleUserEntity(
        id: 'user-1',
        email: 'user1@example.com',
        displayName: 'User One',
        photoUrl: 'https://example.com/1.png',
      );

      final user2 = GoogleUserEntity.fromGoogleSignInAccount(mockAccount);

      expect(user1.id, 'user-1');
      expect(user1.email, 'user1@example.com');
      expect(user1.displayName, 'User One');
      expect(user1.photoUrl, 'https://example.com/1.png');

      expect(user2.id, 'usr-123456789');
      expect(user2.email, 'alice@example.com');
      expect(user2.displayName, 'Alice Cooper');
      expect(user2.photoUrl, 'https://avatar.example.com/alice.jpg');

      final user1Copy = user1.copyWith(displayName: 'Updated Name');
      expect(user1Copy.displayName, 'Updated Name');
      expect(user1Copy.id, 'user-1');

      final user1Identical = GoogleUserEntity(
        id: 'user-1',
        email: 'user1@example.com',
      );
      expect(user1 == user1Identical, isTrue);
      expect(user1.hashCode == user1Identical.hashCode, isTrue);
      expect(user1.toString(), contains('user1@example.com'));
    });

    test('repository initially reports unauthenticated', () {
      expect(repository.isSignedIn, isFalse);
      expect(repository.currentUser, isNull);
      expect(repository.getDriveApi(), isNull);
    });

    test('signIn maps account to GoogleUserEntity', () async {
      fakeSignIn.mockAccount = mockAccount;

      final user = await repository.signIn();

      expect(user, isNotNull);
      expect(user!.id, 'usr-123456789');
      expect(user.email, 'alice@example.com');
      expect(user.displayName, 'Alice Cooper');
      expect(repository.isSignedIn, isTrue);
      expect(repository.currentUser, equals(user));
    });

    test('signInSilently maps account to GoogleUserEntity', () async {
      fakeSignIn.mockAccount = mockAccount;

      final user = await repository.signInSilently();

      expect(user, isNotNull);
      expect(user!.email, 'alice@example.com');
      expect(repository.isSignedIn, isTrue);
    });

    test('authStateChanges stream emits updates on sign in and sign out', () async {
      final emittedUsers = <GoogleUserEntity?>[];
      final sub = repository.authStateChanges.listen((u) => emittedUsers.add(u));

      fakeSignIn.mockAccount = mockAccount;
      await repository.signIn();

      await repository.signOut();

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emittedUsers.length, 2);
      expect(emittedUsers[0]?.email, 'alice@example.com');
      expect(emittedUsers[1], isNull);
    });

    test('getAuthHeaders delegates to auth service', () async {
      fakeSignIn.mockAccount = mockAccount;

      final headers = await repository.getAuthHeaders();

      expect(headers['Authorization'], 'Bearer test-token');
    });
  });
}
