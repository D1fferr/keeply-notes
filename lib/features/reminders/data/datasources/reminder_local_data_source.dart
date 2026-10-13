import '../../domain/reminder_entity.dart';

/// Contract for low-level database operations on reminders.
abstract interface class ReminderLocalDataSource {
  Future<ReminderEntity?> getReminderByNoteId(String noteId);

  Future<ReminderEntity?> getReminderById(String id);

  Future<List<ReminderEntity>> getAllActiveReminders();

  Stream<ReminderEntity?> watchReminderByNoteId(String noteId);

  Future<ReminderEntity> upsertReminder({
    required String id,
    required String noteId,
    required DateTime startDateTime,
    required String repeatType,
    int? customDaysInterval,
    required bool isEnabled,
  });

  Future<ReminderEntity> updateReminderEnabled(String id, bool isEnabled);

  Future<void> deleteReminder(String id);

  Future<void> deleteReminderByNoteId(String noteId);

  // ─── Sub-reminders ──────────────────────────────────────────────────────────

  Future<List<SubReminderEntity>> getSubRemindersByReminderId(String reminderId);

  Stream<List<SubReminderEntity>> watchSubRemindersByReminderId(String reminderId);

  Future<SubReminderEntity> insertSubReminder({
    required String id,
    required String reminderId,
    required String type,
    int? offsetMinutes,
    String? exactTime,
  });

  Future<void> replaceSubReminders({
    required String reminderId,
    required List<SubReminderEntity> subReminders,
  });

  Future<void> deleteSubReminder(String id);

  Future<void> deleteSubRemindersByReminderId(String reminderId);
}
