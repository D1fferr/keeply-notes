import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/services/recurrence_calculator.dart';
import '../../domain/services/sub_reminder_calculator.dart';
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

  /// Generates a deterministic positive 31-bit integer notification ID for a sub-reminder.
  int _subNotificationId(String subReminderId) =>
      subReminderId.hashCode & 0x7FFFFFFF;

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

    // Schedule or cancel native alarms based on enabled status
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
    AppLogger.info('Rescheduling all active reminders and sub-reminders...');
    final activeReminders = await _dataSource.getAllActiveReminders();

    for (final reminder in activeReminders) {
      try {
        await _scheduleNativeNotification(reminder);
      } catch (e, st) {
        AppLogger.error('Failed to reschedule reminder ${reminder.id}', e, st);
      }
    }
    AppLogger.info(
        'Successfully rescheduled ${activeReminders.length} active reminders.');
  }

  // ─── Sub-reminders ──────────────────────────────────────────────────────────

  @override
  Future<List<SubReminderEntity>> getSubReminders(String reminderId) =>
      _dataSource.getSubRemindersByReminderId(reminderId);

  @override
  Stream<List<SubReminderEntity>> watchSubReminders(String reminderId) =>
      _dataSource.watchSubRemindersByReminderId(reminderId);

  @override
  Future<SubReminderEntity> addSubReminder({
    required String reminderId,
    required SubReminderType type,
    int? offsetMinutes,
    String? exactTime,
    String? noteTitle,
  }) async {
    final current = await _dataSource.getSubRemindersByReminderId(reminderId);
    if (current.length >= SubReminderCalculator.maxSubReminders) {
      throw StateError(
        'Cannot exceed maximum of ${SubReminderCalculator.maxSubReminders} sub-reminders per reminder.',
      );
    }

    final subId = _uuid.v4();
    final sub = await _dataSource.insertSubReminder(
      id: subId,
      reminderId: reminderId,
      type: type.toDbString(),
      offsetMinutes: offsetMinutes,
      exactTime: exactTime,
    );

    // If parent reminder is currently active, schedule this sub-reminder alarm
    final parent = await _dataSource.getReminderById(reminderId);
    if (parent != null && parent.isEnabled) {
      final primaryTrigger = RecurrenceCalculator.getNextTriggerDate(
        startDateTime: parent.startDateTime,
        repeatType: parent.repeatType,
        customDaysInterval: parent.customDaysInterval,
      );

      if (primaryTrigger != null) {
        final subTrigger = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primaryTrigger,
          subReminder: sub,
        );

        if (subTrigger != null &&
            SubReminderCalculator.isFutureTrigger(
                triggerDateTime: subTrigger)) {
          final zonedTime = _notificationService.toZonedTime(subTrigger);
          final title = (noteTitle != null && noteTitle.trim().isNotEmpty)
              ? noteTitle.trim()
              : 'Note Reminder';

          await _notificationService.scheduleZonedNotification(
            id: _subNotificationId(sub.id),
            title: title,
            body:
                'Sub-reminder (${SubReminderCalculator.formatDescription(sub)})',
            scheduledDate: zonedTime,
            payload: parent.noteId,
            isSubReminder: true,
          );
        }
      }
    }

    return sub;
  }

  @override
  Future<void> setSubRemindersForReminder({
    required String reminderId,
    required List<SubReminderEntity> subReminders,
    String? noteTitle,
  }) async {
    final capped =
        subReminders.take(SubReminderCalculator.maxSubReminders).toList();

    // Cancel old sub-notifications
    final oldSubs =
        await _dataSource.getSubRemindersByReminderId(reminderId);
    for (final old in oldSubs) {
      await _notificationService.cancelNotification(_subNotificationId(old.id));
    }

    // Persist new sub-reminders
    await _dataSource.replaceSubReminders(
      reminderId: reminderId,
      subReminders: capped,
    );

    // Schedule active sub-alarms if parent is enabled
    final parent = await _dataSource.getReminderById(reminderId);
    if (parent != null && parent.isEnabled) {
      final primaryTrigger = RecurrenceCalculator.getNextTriggerDate(
        startDateTime: parent.startDateTime,
        repeatType: parent.repeatType,
        customDaysInterval: parent.customDaysInterval,
      );

      if (primaryTrigger != null) {
        for (final sub in capped) {
          final subTrigger = SubReminderCalculator.calculateTriggerDateTime(
            primaryTriggerDateTime: primaryTrigger,
            subReminder: sub,
          );

          if (subTrigger != null &&
              SubReminderCalculator.isFutureTrigger(
                  triggerDateTime: subTrigger)) {
            final zonedTime = _notificationService.toZonedTime(subTrigger);
            final title = (noteTitle != null && noteTitle.trim().isNotEmpty)
                ? noteTitle.trim()
                : 'Note Reminder';

            await _notificationService.scheduleZonedNotification(
              id: _subNotificationId(sub.id),
              title: title,
              body:
                  'Sub-reminder (${SubReminderCalculator.formatDescription(sub)})',
              scheduledDate: zonedTime,
              payload: parent.noteId,
              isSubReminder: true,
            );
          }
        }
      }
    }
  }

  @override
  Future<void> deleteSubReminder(String id) async {
    await _notificationService.cancelNotification(_subNotificationId(id));
    await _dataSource.deleteSubReminder(id);
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
      // Also cancel any sub-reminders
      await _cancelSubRemindersForReminder(reminder.id);
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

    // 1. Schedule primary reminder alarm
    await _notificationService.scheduleZonedNotification(
      id: notifId,
      title: title,
      body: body,
      scheduledDate: zonedTime,
      payload: reminder.noteId,
      isSubReminder: false,
    );

    // 2. Schedule all sub-reminders for this reminder alongside primary trigger
    await _scheduleSubRemindersForReminder(
      reminder: reminder,
      primaryTriggerDate: nextTrigger,
      noteTitle: noteTitle,
    );
  }

  Future<void> _scheduleSubRemindersForReminder({
    required ReminderEntity reminder,
    required DateTime primaryTriggerDate,
    String? noteTitle,
  }) async {
    final subReminders =
        await _dataSource.getSubRemindersByReminderId(reminder.id);

    for (final sub in subReminders) {
      final subNotifId = _subNotificationId(sub.id);

      final subTrigger = SubReminderCalculator.calculateTriggerDateTime(
        primaryTriggerDateTime: primaryTriggerDate,
        subReminder: sub,
      );

      if (subTrigger == null ||
          !SubReminderCalculator.isFutureTrigger(
              triggerDateTime: subTrigger)) {
        await _notificationService.cancelNotification(subNotifId);
        continue;
      }

      final zonedTime = _notificationService.toZonedTime(subTrigger);
      final title = (noteTitle != null && noteTitle.trim().isNotEmpty)
          ? noteTitle.trim()
          : 'Note Reminder';

      await _notificationService.scheduleZonedNotification(
        id: subNotifId,
        title: title,
        body: 'Sub-reminder (${SubReminderCalculator.formatDescription(sub)})',
        scheduledDate: zonedTime,
        payload: reminder.noteId,
        isSubReminder: true,
      );
    }
  }

  Future<void> _cancelSubRemindersForReminder(String reminderId) async {
    final subReminders =
        await _dataSource.getSubRemindersByReminderId(reminderId);
    for (final sub in subReminders) {
      await _notificationService.cancelNotification(_subNotificationId(sub.id));
    }
  }

  Future<void> _cancelNativeNotification(String reminderId) async {
    final notifId = _notificationId(reminderId);
    await _notificationService.cancelNotification(notifId);
    await _cancelSubRemindersForReminder(reminderId);
  }
}
