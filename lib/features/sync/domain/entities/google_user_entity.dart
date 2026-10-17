import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Represents an authenticated Google account user.
///
/// Contains the stable [id] (Google User ID) which is used as the key material
/// for deriving end-to-end encryption keys (Task 6.2).
@immutable
class GoogleUserEntity {
  const GoogleUserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.serverAuthCode,
  });

  /// The unique, persistent Google User ID.
  final String id;

  /// User's primary email address.
  final String email;

  /// User's display name.
  final String? displayName;

  /// URL of the user's Google profile photo.
  final String? photoUrl;

  /// Optional server authorization code for backend token exchange.
  final String? serverAuthCode;

  /// Creates a [GoogleUserEntity] from a [GoogleSignInAccount].
  factory GoogleUserEntity.fromGoogleSignInAccount(GoogleSignInAccount account) {
    return GoogleUserEntity(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      serverAuthCode: account.serverAuthCode,
    );
  }

  GoogleUserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? serverAuthCode,
  }) {
    return GoogleUserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      serverAuthCode: serverAuthCode ?? this.serverAuthCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleUserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() =>
      'GoogleUserEntity(id: $id, email: $email, displayName: $displayName)';
}
