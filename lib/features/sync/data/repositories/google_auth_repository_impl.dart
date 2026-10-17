import 'dart:async';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../../core/services/google_auth_service.dart';
import '../../domain/entities/google_user_entity.dart';
import '../../domain/repositories/google_auth_repository.dart';

/// Concrete implementation of [GoogleAuthRepository] backed by [GoogleAuthService].
class GoogleAuthRepositoryImpl implements GoogleAuthRepository {
  GoogleAuthRepositoryImpl(this._authService);

  final GoogleAuthService _authService;

  @override
  Stream<GoogleUserEntity?> get authStateChanges =>
      _authService.onCurrentUserChanged.map((account) =>
          account != null ? GoogleUserEntity.fromGoogleSignInAccount(account) : null);

  @override
  GoogleUserEntity? get currentUser {
    final account = _authService.currentUser;
    return account != null ? GoogleUserEntity.fromGoogleSignInAccount(account) : null;
  }

  @override
  bool get isSignedIn => _authService.isSignedIn;

  @override
  Future<GoogleUserEntity?> signIn() async {
    final account = await _authService.signIn();
    return account != null ? GoogleUserEntity.fromGoogleSignInAccount(account) : null;
  }

  @override
  Future<GoogleUserEntity?> signInSilently() async {
    final account = await _authService.signInSilently();
    return account != null ? GoogleUserEntity.fromGoogleSignInAccount(account) : null;
  }

  @override
  Future<void> signOut() => _authService.signOut();

  @override
  Future<void> disconnect() => _authService.disconnect();

  @override
  Future<Map<String, String>> getAuthHeaders({bool forceRefresh = false}) =>
      _authService.getAuthHeaders(forceRefresh: forceRefresh);

  @override
  Future<void> clearAuthCache() => _authService.clearAuthCache();

  @override
  drive.DriveApi? getDriveApi() => _authService.getDriveApi();
}
