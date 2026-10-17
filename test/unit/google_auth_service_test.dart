import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keeply_notes/core/services/google_auth_service.dart';

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  FakeGoogleSignInAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.serverAuthCode,
    Map<String, String>? authHeaders,
  }) : _authHeaders = authHeaders ?? {'Authorization': 'Bearer mock-token-123'};

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
  bool clearCacheCalled = false;

  @override
  Future<Map<String, String>> get authHeaders async => _authHeaders;

  @override
  Future<void> clearAuthCache() async {
    clearCacheCalled = true;
  }
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  FakeGoogleSignInAccount? mockAccount;
  final StreamController<GoogleSignInAccount?> _userController =
      StreamController<GoogleSignInAccount?>.broadcast();
  bool signInThrows = false;
  bool signOutThrows = false;
  bool disconnectThrows = false;

  @override
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _userController.stream;

  @override
  GoogleSignInAccount? get currentUser => mockAccount;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (signInThrows) throw Exception('Sign-in failed');
    _userController.add(mockAccount);
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool reAuthenticate = false,
    bool suppressErrors = true,
  }) async {
    if (signInThrows) throw Exception('Silent sign-in failed');
    _userController.add(mockAccount);
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    if (signOutThrows) throw Exception('Sign-out failed');
    mockAccount = null;
    _userController.add(null);
    return null;
  }

  @override
  Future<GoogleSignInAccount?> disconnect() async {
    if (disconnectThrows) throw Exception('Disconnect failed');
    mockAccount = null;
    _userController.add(null);
    return null;
  }
}

void main() {
  group('GoogleAuthService & GoogleAuthClient Tests (Task 6.1)', () {
    late FakeGoogleSignIn fakeSignIn;
    late GoogleAuthService service;
    late FakeGoogleSignInAccount testAccount;

    setUp(() {
      fakeSignIn = FakeGoogleSignIn();
      testAccount = FakeGoogleSignInAccount(
        id: 'google-user-98765',
        email: 'tester@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/avatar.png',
      );
      service = GoogleAuthService(googleSignIn: fakeSignIn);
    });

    test('initial state is unauthenticated', () {
      expect(service.isSignedIn, isFalse);
      expect(service.currentUser, isNull);
      expect(service.getDriveApi(), isNull);
    });

    test('signIn returns account and marks signed in', () async {
      fakeSignIn.mockAccount = testAccount;

      final result = await service.signIn();

      expect(result, isNotNull);
      expect(result!.id, 'google-user-98765');
      expect(result.email, 'tester@example.com');
      expect(service.isSignedIn, isTrue);
      expect(service.getDriveApi(), isNotNull);
    });

    test('signIn throws exception when platform sign-in fails', () async {
      fakeSignIn.signInThrows = true;

      expect(() => service.signIn(), throwsA(isA<Exception>()));
    });

    test('signInSilently returns account on success', () async {
      fakeSignIn.mockAccount = testAccount;

      final result = await service.signInSilently();

      expect(result, isNotNull);
      expect(result!.email, 'tester@example.com');
      expect(service.isSignedIn, isTrue);
    });

    test('signInSilently returns null gracefully on error', () async {
      fakeSignIn.signInThrows = true;

      final result = await service.signInSilently();

      expect(result, isNull);
    });

    test('signOut clears current account', () async {
      fakeSignIn.mockAccount = testAccount;
      expect(service.isSignedIn, isTrue);

      await service.signOut();

      expect(service.isSignedIn, isFalse);
      expect(service.currentUser, isNull);
    });

    test('disconnect clears account and revokes access', () async {
      fakeSignIn.mockAccount = testAccount;

      await service.disconnect();

      expect(service.isSignedIn, isFalse);
      expect(service.currentUser, isNull);
    });

    test('clearAuthCache calls account clearAuthCache', () async {
      fakeSignIn.mockAccount = testAccount;

      await service.clearAuthCache();

      expect(testAccount.clearCacheCalled, isTrue);
    });

    test('getAuthHeaders throws StateError when unauthenticated', () async {
      fakeSignIn.mockAccount = null;

      expect(() => service.getAuthHeaders(), throwsStateError);
    });

    test('getAuthHeaders returns headers when authenticated', () async {
      fakeSignIn.mockAccount = testAccount;

      final headers = await service.getAuthHeaders();

      expect(headers['Authorization'], 'Bearer mock-token-123');
    });

    test('GoogleAuthClient attaches auth headers to HTTP requests', () async {
      fakeSignIn.mockAccount = testAccount;

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer mock-token-123');
        return http.Response('{"kind": "drive#fileList"}', 200);
      });

      final authClient = GoogleAuthClient(
        getHeaders: () => service.getAuthHeaders(),
        onUnauthorized: () => service.clearAuthCache(),
        innerClient: mockClient,
      );

      final response = await authClient.get(Uri.parse('https://www.googleapis.com/drive/v3/files'));

      expect(response.statusCode, 200);
      expect(response.body, contains('drive#fileList'));
    });

    test('GoogleAuthClient triggers onUnauthorized on 401 response', () async {
      fakeSignIn.mockAccount = testAccount;
      bool onUnauthorizedCalled = false;

      final mockClient = MockClient((request) async {
        return http.Response('{"error": "invalid_token"}', 401);
      });

      final authClient = GoogleAuthClient(
        getHeaders: () => service.getAuthHeaders(),
        onUnauthorized: () async {
          onUnauthorizedCalled = true;
          await service.clearAuthCache();
        },
        innerClient: mockClient,
      );

      final response = await authClient.get(Uri.parse('https://www.googleapis.com/drive/v3/files'));

      expect(response.statusCode, 401);
      expect(onUnauthorizedCalled, isTrue);
      expect(testAccount.clearCacheCalled, isTrue);
    });
  });
}
