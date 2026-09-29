class AppConstants {
  AppConstants._();

  static const String appName = 'Keeply Notes';
  static const String appVersion = '1.0.0';

  // Security & Encryption
  static const String dbKeySecureStorageKey = 'keeply_notes_db_encryption_key';
  static const String syncSalt = 'keeply_notes_e2ee_salt_v1';

  // Sub-reminders Limits
  static const int maxSubReminders = 10;

  // Folder Constants
  static const String rootFolderId = 'root';
}
