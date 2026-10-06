import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/services/recurrence_calculator.dart';
import '../datasources/reminder_local_data_source.dart';

/// Concrete implementation of [ReminderRepository] coordinating Drift database persistence,
/// recurrence calculation, and native notification scheduling via [NotificationService].
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({
    required ReminderLocalDataSource dataSource,
    required NotificationService notificationService,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _notificationService = notificationService,
        _uuid = uuid ?? const Uuid();

  final ReminderLocalDataSource _dataSource;
  final NotificationService _notificationService;
  final Uuid _uuid;

  /// Generates a deterministic positive 31-bit integer notification ID from a UUID.
  int _notificationId(String reminderId) => reminderId.hashCode & 0x7FFFFFFF;

  @override
  Future<ReminderEntity?> getReminderByNoteId(String noteId) =>
      _dataSource.getReminderByNoteId(noteId);

  @override
  Future<ReminderEntity?> getReminderById(String id) =>
      _dataSource.getReminderById(id);

  @override
  Future<List<ReminderEntity>> getAllActiveReminders() =>
      _dataSource.getAllActiveReminders();

  @override
  Stream<ReminderEntity?> watchReminderForNote(String noteId) =>
      _dataSource.watchReminderByNoteId(noteId);

  @override
  Future<ReminderEntity> setReminder({
    required String noteId,
    required DateTime startDateTime,
    required RepeatType repeatType,
    int? customDaysInterval,
    bool isEnabled = true,
    String? noteTitle,
  }) async {
    final reminderId = _uuid.v4();

    final entity = await _dataSource.upsertReminder(
      id: reminderId,
      noteId: noteId,
      startDateTime: startDateTime,
      repeatType: repeatType.toDbString(),
      customDaysInterval: customDaysInterval,
      isEnabled: isEnabled,
    );

    // Schedule or cancel native alarm based on enabled status
    if (isEnabled) {
      await _scheduleNativeNotification(entity, noteTitle: noteTitle);
    } else {
      await _cancelNativeNotification(entity.id);
    }

    return entity;
  }

  @override
  Future<ReminderEntity> toggleReminderEnabled(
    String id,
    bool isEnabled, {
    String? noteTitle,
  }) async {
    final entity = await _dataSource.updateReminderEnabled(id, isEnabled);

    if (isEnabled) {
      await _scheduleNativeNotification(entity, noteTitle: noteTitle);
    } else {
      await _cancelNativeNotification(entity.id);
    }

    return entity;
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _cancelNativeNotification(id);
    await _dataSource.deleteReminder(id);
  }

  @override
  Future<void> deleteReminderForNote(String noteId) async {
    final existing = await _dataSource.getReminderByNoteId(noteId);
    if (existing != null) {
      await _cancelNativeNotification(existing.id);
    }
    await _dataSource.deleteReminderByNoteId(noteId);
  }

  @override
  Future<void> rescheduleAllActiveReminders() async {
    AppLogger.info('Rescheduling all active reminders...');
    final activeReminders = await _dataSource.getAllActiveReminders();

    for (final reminder in activeReminders) {
      try {
        await _scheduleNativeNotification(reminder);
      } catch (e, st) {
        AppLogger.error('Failed to reschedule reminder ${reminder.id}', e, st);
      }
    }
    AppLogger.info('Successfully rescheduled ${activeReminders.length} active reminders.');
  }

  // ─── Notification Scheduling Helpers ─────────────────────────────────────

  Future<void> _scheduleNativeNotification(
    ReminderEntity reminder, {
    String? noteTitle,
  }) async {
    final nextTrigger = RecurrenceCalculator.getNextTriggerDate(
      startDateTime: reminder.startDateTime,
      repeatType: reminder.repeatType,
      customDaysInterval: reminder.customDaysInterval,
    );

    final notifId = _notificationId(reminder.id);

    if (nextTrigger == null) {
      // The trigger date has elapsed for a non-recurring reminder
      await _notificationService.cancelNotification(notifId);
      return;
    }

    final zonedTime = _notificationService.toZonedTime(nextTrigger);
    final title = (noteTitle != null && noteTitle.trim().isNotEmpty)
        ? noteTitle.trim()
        : 'Note Reminder';

    final body = switch (reminder.repeatType) {
      RepeatType.none => 'Scheduled reminder',
      RepeatType.daily => 'Daily reminder',
      RepeatType.weekly => 'Weekly reminder',
      RepeatType.monthly => 'Monthly reminder',
      RepeatType.yearly => 'Yearly reminder',
      RepeatType.customDays =>
        'Reminder (every ${reminder.customDaysInterval ?? 1} days)',
    };

    await _notificationService.scheduleZonedNotification(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: zonedTime,
      payload: reminder.noteId,
      isSubReminder: false,
    );
  }

  Future<void> _cancelNativeNotification(String reminderId) async {
    final notifId = _notificationId(reminderId);
    await _notificationService.cancelNotification(notifId);
  }
}
