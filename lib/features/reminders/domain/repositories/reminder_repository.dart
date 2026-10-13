import '../reminder_entity.dart';

/// Contract for primary reminder persistence and native notification scheduling.
abstract interface class ReminderRepository {
  /// Fetches the primary reminder linked to [noteId], or null if none exists.
  Future<ReminderEntity?> getReminderByNoteId(String noteId);

  /// Fetches a reminder by its primary key [id].
  Future<ReminderEntity?> getReminderById(String id);

  /// Retrieves all enabled reminders across all notes.
  Future<List<ReminderEntity>> getAllActiveReminders();

  /// Real-time stream of the reminder for [noteId].
  Stream<ReminderEntity?> watchReminderForNote(String noteId);

  /// Creates or updates a primary reminder for [noteId] and schedules the native notification.
  Future<ReminderEntity> setReminder({
    required String noteId,
    required DateTime startDateTime,
    required RepeatType repeatType,
    int? customDaysInterval,
    bool isEnabled = true,
    String? noteTitle,
  });

  /// Enables or disables a reminder, scheduling or cancelling the native alarm.
  Future<ReminderEntity> toggleReminderEnabled(
    String id,
    bool isEnabled, {
    String? noteTitle,
  });

  /// Cancels native alarm and deletes reminder from database.
  Future<void> deleteReminder(String id);

  /// Cancels native alarm and deletes reminder for [noteId] from database.
  Future<void> deleteReminderForNote(String noteId);

  /// Reschedules all active reminders (called upon app reboot or app bootstrap).
  Future<void> rescheduleAllActiveReminders();

  // ─── Sub-reminders ──────────────────────────────────────────────────────────

  /// Retrieves all sub-reminders associated with [reminderId].
  Future<List<SubReminderEntity>> getSubReminders(String reminderId);

  /// Real-time stream of all sub-reminders for [reminderId].
  Stream<List<SubReminderEntity>> watchSubReminders(String reminderId);

  /// Adds a single sub-reminder (enforcing max 10 sub-reminders per reminder)
  /// and schedules its native notification if parent reminder is active.
  Future<SubReminderEntity> addSubReminder({
    required String reminderId,
    required SubReminderType type,
    int? offsetMinutes,
    String? exactTime,
    String? noteTitle,
  });

  /// Replaces all sub-reminders for [reminderId] with [subReminders] (enforcing max 10),
  /// rescheduling native notifications accordingly.
  Future<void> setSubRemindersForReminder({
    required String reminderId,
    required List<SubReminderEntity> subReminders,
    String? noteTitle,
  });

  /// Cancels native notification and deletes a specific sub-reminder by [id].
  Future<void> deleteSubReminder(String id);
}
