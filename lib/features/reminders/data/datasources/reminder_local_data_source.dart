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
}
