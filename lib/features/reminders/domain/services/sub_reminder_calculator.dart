import '../reminder_entity.dart';

/// Calculation engine for secondary sub-reminders triggers.
///
/// Computes trigger [DateTime] for [SubReminderType.offsetMinutes]
/// and [SubReminderType.exactTime] relative to a primary reminder's trigger.
abstract final class SubReminderCalculator {
  /// Maximum number of sub-reminders allowed per primary reminder.
  static const int maxSubReminders = 10;

  /// Calculates the trigger [DateTime] for a given [subReminder]
  /// based on the primary reminder's trigger [primaryTriggerDateTime].
  ///
  /// Returns `null` if [exactTime] is malformed.
  static DateTime? calculateTriggerDateTime({
    required DateTime primaryTriggerDateTime,
    required SubReminderEntity subReminder,
  }) {
    switch (subReminder.type) {
      case SubReminderType.offsetMinutes:
        final offset = subReminder.offsetMinutes ?? 0;
        return primaryTriggerDateTime.add(Duration(minutes: offset));

      case SubReminderType.exactTime:
        final raw = subReminder.exactTime?.trim();
        if (raw == null || raw.isEmpty) return null;

        final parts = raw.split(':');
        if (parts.length != 2) return null;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) return null;
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

        return DateTime(
          primaryTriggerDateTime.year,
          primaryTriggerDateTime.month,
          primaryTriggerDateTime.day,
          hour,
          minute,
        );
    }
  }

  /// Determines whether the [triggerDateTime] is strictly in the future
  /// relative to [referenceTime] (defaults to [DateTime.now]).
  static bool isFutureTrigger({
    required DateTime? triggerDateTime,
    DateTime? referenceTime,
  }) {
    if (triggerDateTime == null) return false;
    final now = referenceTime ?? DateTime.now();
    return triggerDateTime.isAfter(now);
  }

  /// Returns a clean, human-readable label for a sub-reminder.
  static String formatDescription(SubReminderEntity subReminder) {
    switch (subReminder.type) {
      case SubReminderType.offsetMinutes:
        final offset = subReminder.offsetMinutes ?? 0;
        if (offset > 0) {
          if (offset % 60 == 0) {
            final hours = offset ~/ 60;
            return '+$hours ${hours == 1 ? 'hour' : 'hours'}';
          }
          return '+$offset min';
        } else if (offset < 0) {
          final abs = offset.abs();
          if (abs % 60 == 0) {
            final hours = abs ~/ 60;
            return '-$hours ${hours == 1 ? 'hour' : 'hours'}';
          }
          return '$offset min';
        }
        return 'At time of reminder';

      case SubReminderType.exactTime:
        final time = subReminder.exactTime ?? '';
        return 'Exact: $time';
    }
  }
}
