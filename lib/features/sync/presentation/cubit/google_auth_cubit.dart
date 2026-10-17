import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/google_user_entity.dart';
import '../../domain/repositories/google_auth_repository.dart';
import 'google_auth_state.dart';

/// Cubit managing Google Authentication lifecycle, silent session restoration,
/// and reactive state updates for Google Drive sync.
class GoogleAuthCubit extends ChangeNotifier {
  GoogleAuthCubit({
    required GoogleAuthRepository authRepository,
    bool autoInitialize = true,
  }) : _authRepository = authRepository {
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthStateChanged);

    if (autoInitialize) {
      init();
    }
  }

  final GoogleAuthRepository _authRepository;
  StreamSubscription<GoogleUserEntity?>? _authSubscription;

  GoogleAuthState _state = const GoogleAuthInitial();
  GoogleAuthState get state => _state;

  GoogleUserEntity? get currentUser => _authRepository.currentUser;
  bool get isSignedIn => _authRepository.isSignedIn;

  void _onAuthStateChanged(GoogleUserEntity? user) {
    if (user != null) {
      _emit(GoogleAuthAuthenticated(user));
    } else if (_state is! GoogleAuthLoading) {
      _emit(const GoogleAuthUnauthenticated());
    }
  }

  void _emit(GoogleAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Restores previous authenticated session silently without prompting user UI.
  Future<void> init() async {
    _emit(const GoogleAuthLoading(message: 'Checking Google account session...'));
    try {
      final user = await _authRepository.signInSilently();
      if (user != null) {
        _emit(GoogleAuthAuthenticated(user));
      } else {
        _emit(const GoogleAuthUnauthenticated());
      }
    } catch (e, st) {
      AppLogger.error('GoogleAuthCubit: silent sign-in error', e, st);
      _emit(const GoogleAuthUnauthenticated());
    }
  }

  /// Prompts the user with the interactive Google Sign-In sheet.
  Future<bool> signIn() async {
    _emit(const GoogleAuthLoading(message: 'Connecting to Google...'));
    try {
      final user = await _authRepository.signIn();
      if (user != null) {
        _emit(GoogleAuthAuthenticated(user));
        return true;
      } else {
        // User cancelled interactive sign-in flow
        _emit(const GoogleAuthUnauthenticated());
        return false;
      }
    } catch (e, st) {
      AppLogger.error('GoogleAuthCubit: interactive sign-in error', e, st);
      _emit(GoogleAuthError('Sign in failed: ${e.toString()}'));
      return false;
    }
  }

  /// Signs the user out of Google Account.
  Future<void> signOut() async {
    _emit(const GoogleAuthLoading(message: 'Signing out...'));
    try {
      await _authRepository.signOut();
      _emit(const GoogleAuthUnauthenticated());
    } catch (e, st) {
      AppLogger.error('GoogleAuthCubit: sign-out error', e, st);
      _emit(GoogleAuthError('Sign out failed: ${e.toString()}'));
    }
  }

  /// Disconnects the user account, revoking Drive AppData permissions.
  Future<void> disconnect() async {
    _emit(const GoogleAuthLoading(message: 'Disconnecting account...'));
    try {
      await _authRepository.disconnect();
      _emit(const GoogleAuthUnauthenticated());
    } catch (e, st) {
      AppLogger.error('GoogleAuthCubit: disconnect error', e, st);
      _emit(GoogleAuthError('Disconnect failed: ${e.toString()}'));
    }
  }

  /// Triggers a proactive token cache invalidation and refresh.
  Future<void> refreshTokens() async {
    try {
      await _authRepository.clearAuthCache();
      await _authRepository.getAuthHeaders(forceRefresh: true);
      AppLogger.info('GoogleAuthCubit: tokens refreshed successfully');
    } catch (e, st) {
      AppLogger.error('GoogleAuthCubit: failed to refresh token', e, st);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
