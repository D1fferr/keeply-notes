class AppConstants {
  AppConstants._();

  static const String appName = 'Keeply Notes';
  static const String appVersion = '1.0.0';

  // Security & Encryption
  static const String dbKeySecureStorageKey = 'keeply_notes_db_encryption_key';
  static const String attachmentKeySecureStorageKey = 'keeply_notes_attachment_encryption_key';
  static const String syncSalt = 'keeply_notes_e2ee_salt_v1';

  // Attachments
  static const String attachmentsDirectoryName = 'attachments';

  // Sub-reminders Limits
  static const int maxSubReminders = 10;

  // Folder Constants
  static const String rootFolderId = 'root';
}
