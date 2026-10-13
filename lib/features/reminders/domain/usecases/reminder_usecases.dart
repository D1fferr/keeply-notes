import '../reminder_entity.dart';
import '../repositories/reminder_repository.dart';

/// Fetches the primary reminder for a given note.
class GetReminderForNoteUseCase {
  const GetReminderForNoteUseCase(this._repository);

  final ReminderRepository _repository;

  Future<ReminderEntity?> call(String noteId) =>
      _repository.getReminderByNoteId(noteId);
}

/// Watches real-time updates for a note's primary reminder.
class WatchReminderForNoteUseCase {
  const WatchReminderForNoteUseCase(this._repository);

  final ReminderRepository _repository;

  Stream<ReminderEntity?> call(String noteId) =>
      _repository.watchReminderForNote(noteId);
}

/// Creates or updates a primary reminder and schedules the native notification.
class SetReminderUseCase {
  const SetReminderUseCase(this._repository);

  final ReminderRepository _repository;

  Future<ReminderEntity> call({
    required String noteId,
    required DateTime startDateTime,
    required RepeatType repeatType,
    int? customDaysInterval,
    bool isEnabled = true,
    String? noteTitle,
  }) =>
      _repository.setReminder(
        noteId: noteId,
        startDateTime: startDateTime,
        repeatType: repeatType,
        customDaysInterval: customDaysInterval,
        isEnabled: isEnabled,
        noteTitle: noteTitle,
      );
}

/// Enables or disables a reminder.
class ToggleReminderEnabledUseCase {
  const ToggleReminderEnabledUseCase(this._repository);

  final ReminderRepository _repository;

  Future<ReminderEntity> call(
    String id,
    bool isEnabled, {
    String? noteTitle,
  }) =>
      _repository.toggleReminderEnabled(id, isEnabled, noteTitle: noteTitle);
}

/// Deletes a reminder and cancels its native notifications.
class DeleteReminderUseCase {
  const DeleteReminderUseCase(this._repository);

  final ReminderRepository _repository;

  Future<void> call(String id) => _repository.deleteReminder(id);

  Future<void> forNote(String noteId) =>
      _repository.deleteReminderForNote(noteId);
}

/// Reschedules all active reminders (useful on boot and app start).
class RescheduleAllRemindersUseCase {
  const RescheduleAllRemindersUseCase(this._repository);

  final ReminderRepository _repository;

  Future<void> call() => _repository.rescheduleAllActiveReminders();
}

// ─── Sub-reminders Use Cases ──────────────────────────────────────────────────

/// Fetches all sub-reminders for a given reminder.
class GetSubRemindersUseCase {
  const GetSubRemindersUseCase(this._repository);

  final ReminderRepository _repository;

  Future<List<SubReminderEntity>> call(String reminderId) =>
      _repository.getSubReminders(reminderId);
}

/// Watches real-time updates for a reminder's sub-reminders.
class WatchSubRemindersUseCase {
  const WatchSubRemindersUseCase(this._repository);

  final ReminderRepository _repository;

  Stream<List<SubReminderEntity>> call(String reminderId) =>
      _repository.watchSubReminders(reminderId);
}

/// Adds a sub-reminder to a primary reminder.
class AddSubReminderUseCase {
  const AddSubReminderUseCase(this._repository);

  final ReminderRepository _repository;

  Future<SubReminderEntity> call({
    required String reminderId,
    required SubReminderType type,
    int? offsetMinutes,
    String? exactTime,
    String? noteTitle,
  }) =>
      _repository.addSubReminder(
        reminderId: reminderId,
        type: type,
        offsetMinutes: offsetMinutes,
        exactTime: exactTime,
        noteTitle: noteTitle,
      );
}

/// Replaces all sub-reminders for a primary reminder.
class SetSubRemindersUseCase {
  const SetSubRemindersUseCase(this._repository);

  final ReminderRepository _repository;

  Future<void> call({
    required String reminderId,
    required List<SubReminderEntity> subReminders,
    String? noteTitle,
  }) =>
      _repository.setSubRemindersForReminder(
        reminderId: reminderId,
        subReminders: subReminders,
        noteTitle: noteTitle,
      );
}

/// Deletes a sub-reminder by ID.
class DeleteSubReminderUseCase {
  const DeleteSubReminderUseCase(this._repository);

  final ReminderRepository _repository;

  Future<void> call(String id) => _repository.deleteSubReminder(id);
}

