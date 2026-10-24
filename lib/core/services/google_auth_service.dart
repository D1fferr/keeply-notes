import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Authenticated HTTP client that injects OAuth headers and invokes token refresh handlers.
class GoogleAuthClient extends http.BaseClient {
  GoogleAuthClient({
    required Future<Map<String, String>> Function() getHeaders,
    required Future<void> Function() onUnauthorized,
    http.Client? innerClient,
  })  : _getHeaders = getHeaders,
        _onUnauthorized = onUnauthorized,
        _client = innerClient ?? http.Client();

  final Future<Map<String, String>> Function() _getHeaders;
  final Future<void> Function() _onUnauthorized;
  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await _getHeaders();
    request.headers.addAll(headers);

    final response = await _client.send(request);

    if (response.statusCode == 401) {
      AppLogger.warn('GoogleAuthClient: Received 401 Unauthorized, triggering token refresh handler');
      await _onUnauthorized();
    }

    return response;
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Service managing Google Authentication via [GoogleSignIn] and Google Drive API setup.
///
/// Features:
/// - Requests `drive.DriveApi.driveAppdataScope` for isolated, secure appDataFolder sync.
/// - Interactive [signIn] and silent [signInSilently] flows.
/// - Token refresh handlers that clear auth cache and acquire fresh access tokens.
/// - Provides authenticated [http.Client] and pre-configured [drive.DriveApi] client instances.
class GoogleAuthService {
  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    http.Client? baseHttpClient,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: defaultScopes,
            ),
        _baseHttpClient = baseHttpClient;

  /// Default OAuth scopes requested: restricted to Google Drive hidden `appDataFolder`.
  static const List<String> defaultScopes = [
    drive.DriveApi.driveAppdataScope,
  ];

  final GoogleSignIn _googleSignIn;
  final http.Client? _baseHttpClient;

  /// Stream of current signed in user changes.
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Currently signed in user, or `null` if unauthenticated.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Signs in the user interactively (prompts system/web Google Sign-In sheet).
  Future<GoogleSignInAccount?> signIn() async {
    try {
      AppLogger.info('GoogleAuthService: initiating interactive sign in');
      final account = await _googleSignIn.signIn();
      if (account != null) {
        AppLogger.info('GoogleAuthService: sign in successful for ${account.email}');
      } else {
        AppLogger.info('GoogleAuthService: sign in cancelled by user');
      }
      return account;
    } catch (e, st) {
      AppLogger.error('GoogleAuthService: sign in failed', e, st);
      rethrow;
    }
  }

  /// Attempts silent sign in without showing any user prompts (e.g. on application startup).
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      AppLogger.info('GoogleAuthService: attempting silent sign in');
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        AppLogger.info('GoogleAuthService: silent sign in restored for ${account.email}');
      } else {
        AppLogger.debug('GoogleAuthService: silent sign in returned no existing session');
      }
      return account;
    } catch (e, st) {
      AppLogger.error('GoogleAuthService: silent sign in failed', e, st);
      return null;
    }
  }

  /// Signs out the current user and clears active session tokens.
  Future<void> signOut() async {
    try {
      AppLogger.info('GoogleAuthService: signing out current user');
      await _googleSignIn.signOut();
      AppLogger.info('GoogleAuthService: sign out complete');
    } catch (e, st) {
      AppLogger.error('GoogleAuthService: sign out failed', e, st);
      rethrow;
    }
  }

  /// Disconnects the user and revokes application access tokens.
  Future<void> disconnect() async {
    try {
      AppLogger.info('GoogleAuthService: disconnecting user account');
      await _googleSignIn.disconnect();
      AppLogger.info('GoogleAuthService: disconnect complete');
    } catch (e, st) {
      AppLogger.error('GoogleAuthService: disconnect failed', e, st);
      rethrow;
    }
  }

  /// Clears the cached auth token, forcing fresh tokens on the next request.
  Future<void> clearAuthCache() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account != null) {
        await account.clearAuthCache();
        AppLogger.info('GoogleAuthService: cleared auth cache for ${account.email}');
      }
    } catch (e, st) {
      AppLogger.error('GoogleAuthService: clearAuthCache failed', e, st);
    }
  }

  /// Retrieves authorization headers (e.g. `{'Authorization': 'Bearer ...'}`).
  Future<Map<String, String>> getAuthHeaders({bool forceRefresh = false}) async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      throw StateError('Cannot retrieve auth headers: user is not signed in');
    }

    if (forceRefresh) {
      await clearAuthCache();
    }

    try {
      return await account.authHeaders;
    } catch (e, st) {
      AppLogger.warn('GoogleAuthService: failed to get auth headers, clearing cache and retrying', e, st);
      await clearAuthCache();
      return await account.authHeaders;
    }
  }

  /// Returns an authenticated [http.Client] that injects OAuth authorization headers
  /// and automatically invokes the token refresh handler on 401 responses.
  http.Client createAuthenticatedClient() {
    return GoogleAuthClient(
      getHeaders: () => getAuthHeaders(),
      onUnauthorized: () => clearAuthCache(),
      innerClient: _baseHttpClient,
    );
  }

  /// Returns a configured [drive.DriveApi] instance using the authenticated HTTP client,
  /// or `null` if the user is not currently signed in.
  drive.DriveApi? getDriveApi() {
    if (!isSignedIn) return null;
    return drive.DriveApi(createAuthenticatedClient());
  }
}
