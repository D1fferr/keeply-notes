import 'package:googleapis/drive/v3.dart' as drive;
import '../entities/google_user_entity.dart';

/// Repository contract for Google Authentication and Drive API client acquisition.
abstract class GoogleAuthRepository {
  /// Stream emitting updates whenever the authenticated user state changes.
  Stream<GoogleUserEntity?> get authStateChanges;

  /// The currently signed in user, or `null` if unauthenticated.
  GoogleUserEntity? get currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// Initiates interactive Google Sign-In with Google Drive AppData scope.
  Future<GoogleUserEntity?> signIn();

  /// Attempts silent Google Sign-In to restore previous session.
  Future<GoogleUserEntity?> signInSilently();

  /// Signs the current user out.
  Future<void> signOut();

  /// Disconnects the user account and revokes app authorization.
  Future<void> disconnect();

  /// Retrieves authorization headers, optionally forcing token cache invalidation.
  Future<Map<String, String>> getAuthHeaders({bool forceRefresh = false});

  /// Invalidate cached tokens to trigger refresh.
  Future<void> clearAuthCache();

  /// Returns a configured [drive.DriveApi] instance, or `null` if unauthenticated.
  drive.DriveApi? getDriveApi();
}
