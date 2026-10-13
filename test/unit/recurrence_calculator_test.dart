import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/features/reminders/domain/reminder_entity.dart';
import 'package:keeply_notes/features/reminders/domain/services/recurrence_calculator.dart';

void main() {
  group('RecurrenceCalculator Unit Tests (Task 4.2)', () {
    test('returns startDateTime if it is strictly in the future', () {
      final start = DateTime(2026, 10, 10, 10, 0);
      final ref = DateTime(2026, 10, 6, 10, 0);

      final next = RecurrenceCalculator.getNextTriggerDate(
        startDateTime: start,
        repeatType: RepeatType.daily,
        after: ref,
      );

      expect(next, equals(start));
    });

    group('RepeatType.none', () {
      test('returns startDateTime when future, null when elapsed', () {
        final start = DateTime(2026, 10, 5, 12, 0);
        final ref = DateTime(2026, 10, 6, 12, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.none,
          after: ref,
        );

        expect(next, isNull);
      });
    });

    group('RepeatType.daily', () {
      test('schedules for later today if time has not passed yet', () {
        final start = DateTime(2026, 10, 1, 18, 0);
        final ref = DateTime(2026, 10, 6, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.daily,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 10, 6, 18, 0)));
      });

      test('schedules for tomorrow if time has already passed today', () {
        final start = DateTime(2026, 10, 1, 9, 0);
        final ref = DateTime(2026, 10, 6, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.daily,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 10, 7, 9, 0)));
      });
    });

    group('RepeatType.weekly', () {
      test('schedules for the matching weekday in current week', () {
        // 2026-10-06 is Tuesday (weekday 2).
        // Suppose startDateTime is Friday (weekday 5) at 14:00.
        final start = DateTime(2026, 10, 2, 14, 0); // Friday
        final ref = DateTime(2026, 10, 6, 10, 0); // Tuesday

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.weekly,
          after: ref,
        );

        // Next should be Friday 2026-10-09 at 14:00
        expect(next, equals(DateTime(2026, 10, 9, 14, 0)));
      });

      test('schedules for next week if matching weekday already elapsed this week', () {
        // 2026-10-06 is Tuesday (weekday 2) at 12:00.
        // Start is Monday (weekday 1) at 10:00.
        final start = DateTime(2026, 9, 28, 10, 0); // Monday
        final ref = DateTime(2026, 10, 6, 12, 0); // Tuesday

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.weekly,
          after: ref,
        );

        // Next Monday should be 2026-10-12 at 10:00
        expect(next, equals(DateTime(2026, 10, 12, 10, 0)));
      });

      test('schedules next week if today is the day but time has passed', () {
        final start = DateTime(2026, 9, 29, 9, 0); // Tuesday
        final ref = DateTime(2026, 10, 6, 11, 0); // Tuesday (later)

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.weekly,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 10, 13, 9, 0)));
      });
    });

    group('RepeatType.monthly', () {
      test('schedules for current month if day has not passed', () {
        final start = DateTime(2026, 8, 20, 15, 0);
        final ref = DateTime(2026, 10, 6, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.monthly,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 10, 20, 15, 0)));
      });

      test('schedules for next month if day has passed', () {
        final start = DateTime(2026, 8, 4, 15, 0);
        final ref = DateTime(2026, 10, 6, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.monthly,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 11, 4, 15, 0)));
      });

      test('clamps day correctly for shorter months (e.g. Jan 31 -> Feb 28)', () {
        final start = DateTime(2026, 1, 31, 10, 0);
        final ref = DateTime(2026, 2, 1, 8, 0); // Feb 2026 has 28 days

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.monthly,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 2, 28, 10, 0)));
      });

      test('advances across year boundaries (Dec -> Jan)', () {
        final start = DateTime(2026, 5, 2, 9, 0);
        final ref = DateTime(2026, 12, 10, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.monthly,
          after: ref,
        );

        expect(next, equals(DateTime(2027, 1, 2, 9, 0)));
      });
    });

    group('RepeatType.yearly', () {
      test('schedules for current year if date is in the future', () {
        final start = DateTime(2025, 12, 25, 10, 0);
        final ref = DateTime(2026, 10, 6, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.yearly,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 12, 25, 10, 0)));
      });

      test('schedules for next year if date has already passed', () {
        final start = DateTime(2025, 3, 15, 10, 0);
        final ref = DateTime(2026, 10, 6, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.yearly,
          after: ref,
        );

        expect(next, equals(DateTime(2027, 3, 15, 10, 0)));
      });

      test('handles Feb 29 leap years properly', () {
        // 2024 is leap year, 2025 is not leap year
        final start = DateTime(2024, 2, 29, 12, 0);
        final ref = DateTime(2025, 1, 1, 10, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.yearly,
          after: ref,
        );

        expect(next, equals(DateTime(2025, 2, 28, 12, 0)));
      });
    });

    group('RepeatType.customDays', () {
      test('schedules in step intervals from start date strictly after reference', () {
        // Start date: Oct 1. Interval: 3 days.
        // Triggers: Oct 4, Oct 7, Oct 10...
        final start = DateTime(2026, 10, 1, 10, 0);
        final ref = DateTime(2026, 10, 5, 12, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.customDays,
          customDaysInterval: 3,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 10, 7, 10, 0)));
      });

      test('defaults to interval of 1 if customDaysInterval is null or <= 0', () {
        final start = DateTime(2026, 10, 1, 10, 0);
        final ref = DateTime(2026, 10, 5, 12, 0);

        final next = RecurrenceCalculator.getNextTriggerDate(
          startDateTime: start,
          repeatType: RepeatType.customDays,
          customDaysInterval: null,
          after: ref,
        );

        expect(next, equals(DateTime(2026, 10, 6, 10, 0)));
      });
    });
  });
}
