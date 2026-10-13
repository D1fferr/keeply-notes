import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/features/reminders/domain/reminder_entity.dart';
import 'package:keeply_notes/features/reminders/domain/services/sub_reminder_calculator.dart';

void main() {
  group('SubReminderCalculator Unit Tests (Task 4.3)', () {
    test('maxSubReminders is exactly 10', () {
      expect(SubReminderCalculator.maxSubReminders, equals(10));
    });

    group('SubReminderType.offsetMinutes', () {
      test('calculates future positive offset in minutes', () {
        final primary = DateTime(2026, 10, 14, 10, 0);
        const sub = SubReminderEntity(
          id: 'sub-1',
          reminderId: 'rem-1',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: 15,
        );

        final trigger = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primary,
          subReminder: sub,
        );

        expect(trigger, equals(DateTime(2026, 10, 14, 10, 15)));
      });

      test('calculates negative offset in minutes (advance warning)', () {
        final primary = DateTime(2026, 10, 14, 10, 0);
        const sub = SubReminderEntity(
          id: 'sub-2',
          reminderId: 'rem-1',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: -30,
        );

        final trigger = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primary,
          subReminder: sub,
        );

        expect(trigger, equals(DateTime(2026, 10, 14, 9, 30)));
      });

      test('handles null offset gracefully as zero offset', () {
        final primary = DateTime(2026, 10, 14, 10, 0);
        const sub = SubReminderEntity(
          id: 'sub-3',
          reminderId: 'rem-1',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: null,
        );

        final trigger = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primary,
          subReminder: sub,
        );

        expect(trigger, equals(primary));
      });
    });

    group('SubReminderType.exactTime', () {
      test('calculates exact time of day on primary reminder date', () {
        final primary = DateTime(2026, 10, 14, 10, 0);
        const sub = SubReminderEntity(
          id: 'sub-4',
          reminderId: 'rem-1',
          type: SubReminderType.exactTime,
          exactTime: '20:30',
        );

        final trigger = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primary,
          subReminder: sub,
        );

        expect(trigger, equals(DateTime(2026, 10, 14, 20, 30)));
      });

      test('handles midnight and late evening exact times', () {
        final primary = DateTime(2026, 10, 14, 15, 0);
        const subMidnight = SubReminderEntity(
          id: 'sub-5',
          reminderId: 'rem-1',
          type: SubReminderType.exactTime,
          exactTime: '00:00',
        );
        const subEnd = SubReminderEntity(
          id: 'sub-6',
          reminderId: 'rem-1',
          type: SubReminderType.exactTime,
          exactTime: '23:59',
        );

        final t1 = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primary,
          subReminder: subMidnight,
        );
        final t2 = SubReminderCalculator.calculateTriggerDateTime(
          primaryTriggerDateTime: primary,
          subReminder: subEnd,
        );

        expect(t1, equals(DateTime(2026, 10, 14, 0, 0)));
        expect(t2, equals(DateTime(2026, 10, 14, 23, 59)));
      });

      test('returns null on invalid or malformed time strings', () {
        final primary = DateTime(2026, 10, 14, 10, 0);

        for (final malformed in [
          null,
          '',
          'invalid',
          '25:00',
          '12:65',
          '12',
          '12:00:00'
        ]) {
          final sub = SubReminderEntity(
            id: 'sub-invalid',
            reminderId: 'rem-1',
            type: SubReminderType.exactTime,
            exactTime: malformed,
          );

          final trigger = SubReminderCalculator.calculateTriggerDateTime(
            primaryTriggerDateTime: primary,
            subReminder: sub,
          );

          expect(trigger, isNull, reason: 'Failed for input: $malformed');
        }
      });
    });

    group('isFutureTrigger', () {
      test('identifies future vs past triggers correctly', () {
        final ref = DateTime(2026, 10, 14, 12, 0);

        expect(
          SubReminderCalculator.isFutureTrigger(
            triggerDateTime: DateTime(2026, 10, 14, 12, 1),
            referenceTime: ref,
          ),
          isTrue,
        );

        expect(
          SubReminderCalculator.isFutureTrigger(
            triggerDateTime: DateTime(2026, 10, 14, 12, 0),
            referenceTime: ref,
          ),
          isFalse,
        );

        expect(
          SubReminderCalculator.isFutureTrigger(
            triggerDateTime: DateTime(2026, 10, 14, 11, 59),
            referenceTime: ref,
          ),
          isFalse,
        );

        expect(
          SubReminderCalculator.isFutureTrigger(
            triggerDateTime: null,
            referenceTime: ref,
          ),
          isFalse,
        );
      });
    });

    group('formatDescription', () {
      test('formats positive offset in minutes and hours', () {
        const sub1 = SubReminderEntity(
          id: '1',
          reminderId: 'r',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: 15,
        );
        const sub2 = SubReminderEntity(
          id: '2',
          reminderId: 'r',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: 60,
        );
        const sub3 = SubReminderEntity(
          id: '3',
          reminderId: 'r',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: 120,
        );

        expect(SubReminderCalculator.formatDescription(sub1), equals('+15 min'));
        expect(SubReminderCalculator.formatDescription(sub2), equals('+1 hour'));
        expect(SubReminderCalculator.formatDescription(sub3), equals('+2 hours'));
      });

      test('formats negative offset in minutes and hours', () {
        const sub1 = SubReminderEntity(
          id: '1',
          reminderId: 'r',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: -10,
        );
        const sub2 = SubReminderEntity(
          id: '2',
          reminderId: 'r',
          type: SubReminderType.offsetMinutes,
          offsetMinutes: -60,
        );

        expect(SubReminderCalculator.formatDescription(sub1), equals('-10 min'));
        expect(SubReminderCalculator.formatDescription(sub2), equals('-1 hour'));
      });

      test('formats exact time', () {
        const sub = SubReminderEntity(
          id: '1',
          reminderId: 'r',
          type: SubReminderType.exactTime,
          exactTime: '20:00',
        );

        expect(SubReminderCalculator.formatDescription(sub), equals('Exact: 20:00'));
      });
    });
  });
}
