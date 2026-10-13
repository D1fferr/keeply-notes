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

  // Notification Channels & Settings
  static const String primaryReminderChannelId = 'keeply_reminders_channel';
  static const String primaryReminderChannelName = 'Keeply Reminders';
  static const String primaryReminderChannelDesc =
      'Notifications for primary note reminders and scheduled tasks';

  static const String subReminderChannelId = 'keeply_sub_reminders_channel';
  static const String subReminderChannelName = 'Keeply Secondary Reminders';
  static const String subReminderChannelDesc =
      'Notifications for follow-up reminders and snooze alerts';
}
