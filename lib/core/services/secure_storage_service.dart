import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Retrieves the existing database encryption key or generates a new 256-bit secure key.
  Future<String> getOrCreateDatabaseKey() async {
    try {
      String? existingKey = await _storage.read(key: AppConstants.dbKeySecureStorageKey);
      if (existingKey != null && existingKey.isNotEmpty) {
        AppLogger.info('Retrieved existing database encryption key from SecureStorage');
        return existingKey;
      }

      // Generate a new 256-bit (32 byte) secure random key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      final newKey = base64UrlEncode(keyBytes);

      await _storage.write(key: AppConstants.dbKeySecureStorageKey, value: newKey);
      AppLogger.info('Generated and stored new database encryption key in SecureStorage');
      return newKey;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get/create database key in SecureStorage', e, stackTrace);
      rethrow;
    }
  }

  /// Read a value from secure storage by key
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Write a value to secure storage by key
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Delete a key from secure storage
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all keys from secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
