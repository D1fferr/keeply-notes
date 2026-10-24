import 'package:flutter/foundation.dart';
import '../../domain/entities/google_user_entity.dart';

/// Represents the reactive state of Google Authentication and Cloud Sync connection.
@immutable
sealed class GoogleAuthState {
  const GoogleAuthState();
}

/// Initial state before authentication check has commenced.
final class GoogleAuthInitial extends GoogleAuthState {
  const GoogleAuthInitial();
}

/// Authentication operation is actively in progress (e.g. signing in, checking silent session).
final class GoogleAuthLoading extends GoogleAuthState {
  const GoogleAuthLoading({this.message});
  final String? message;
}

/// User is successfully signed in with Google and Drive AppData scope is active.
final class GoogleAuthAuthenticated extends GoogleAuthState {
  const GoogleAuthAuthenticated(this.user);
  final GoogleUserEntity user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleAuthAuthenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;
}

/// No user is currently signed in.
final class GoogleAuthUnauthenticated extends GoogleAuthState {
  const GoogleAuthUnauthenticated();
}

/// An error occurred during authentication or token refresh.
final class GoogleAuthError extends GoogleAuthState {
  const GoogleAuthError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleAuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
