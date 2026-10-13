import '../reminder_entity.dart';

/// Calculation engine for recurring reminder triggers.
///
/// Computes the exact next trigger [DateTime] according to [RepeatType]
/// (`none`, `daily`, `weekly`, `monthly`, `yearly`, `customDays`).
abstract final class RecurrenceCalculator {
  /// Calculates the next trigger date strictly after [after] (defaults to [DateTime.now]).
  ///
  /// Returns `null` if [repeatType] is `none` and the trigger date has already passed.
  static DateTime? getNextTriggerDate({
    required DateTime startDateTime,
    required RepeatType repeatType,
    int? customDaysInterval,
    DateTime? after,
  }) {
    final reference = after ?? DateTime.now();

    // If the base startDateTime is already in the future, it is the first trigger
    if (startDateTime.isAfter(reference)) {
      return startDateTime;
    }

    switch (repeatType) {
      case RepeatType.none:
        // One-time reminder whose time has already elapsed
        return null;

      case RepeatType.daily:
        var candidate = DateTime(
          reference.year,
          reference.month,
          reference.day,
          startDateTime.hour,
          startDateTime.minute,
          startDateTime.second,
          startDateTime.millisecond,
        );
        if (!candidate.isAfter(reference)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case RepeatType.weekly:
        var candidate = DateTime(
          reference.year,
          reference.month,
          reference.day,
          startDateTime.hour,
          startDateTime.minute,
          startDateTime.second,
          startDateTime.millisecond,
        );

        final daysUntilWeekday = (startDateTime.weekday - reference.weekday) % 7;
        if (daysUntilWeekday > 0) {
          candidate = candidate.add(Duration(days: daysUntilWeekday));
        } else if (daysUntilWeekday == 0) {
          if (!candidate.isAfter(reference)) {
            candidate = candidate.add(const Duration(days: 7));
          }
        } else {
          candidate = candidate.add(Duration(days: daysUntilWeekday + 7));
        }
        return candidate;

      case RepeatType.monthly:
        var year = reference.year;
        var month = reference.month;

        DateTime candidate = _buildClampedDate(
          year: year,
          month: month,
          day: startDateTime.day,
          hour: startDateTime.hour,
          minute: startDateTime.minute,
          second: startDateTime.second,
        );

        if (!candidate.isAfter(reference)) {
          month += 1;
          if (month > 12) {
            month = 1;
            year += 1;
          }
          candidate = _buildClampedDate(
            year: year,
            month: month,
            day: startDateTime.day,
            hour: startDateTime.hour,
            minute: startDateTime.minute,
            second: startDateTime.second,
          );
        }
        return candidate;

      case RepeatType.yearly:
        var year = reference.year;
        DateTime candidate = _buildClampedDate(
          year: year,
          month: startDateTime.month,
          day: startDateTime.day,
          hour: startDateTime.hour,
          minute: startDateTime.minute,
          second: startDateTime.second,
        );

        if (!candidate.isAfter(reference)) {
          year += 1;
          candidate = _buildClampedDate(
            year: year,
            month: startDateTime.month,
            day: startDateTime.day,
            hour: startDateTime.hour,
            minute: startDateTime.minute,
            second: startDateTime.second,
          );
        }
        return candidate;

      case RepeatType.customDays:
        final interval = (customDaysInterval != null && customDaysInterval > 0)
            ? customDaysInterval
            : 1;

        final diffDays = reference.difference(startDateTime).inDays;
        var steps = (diffDays / interval).floor();
        if (steps < 0) steps = 0;

        var candidate = startDateTime.add(Duration(days: steps * interval));
        while (!candidate.isAfter(reference)) {
          candidate = candidate.add(Duration(days: interval));
        }
        return candidate;
    }
  }

  /// Builds a [DateTime] clamping the day of month to the maximum available days in that month.
  /// (e.g. Feb 31 -> Feb 28 or Feb 29).
  static DateTime _buildClampedDate({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required int second,
  }) {
    final maxDaysInMonth = DateTime(year, month + 1, 0).day;
    final clampedDay = day > maxDaysInMonth ? maxDaysInMonth : day;

    return DateTime(
      year,
      month,
      clampedDay,
      hour,
      minute,
      second,
    );
  }
}
