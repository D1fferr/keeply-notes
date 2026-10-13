import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/constants/app_constants.dart';
import 'package:keeply_notes/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('NotificationService & Timezones Unit Tests (Task 4.1)', () {
    setUpAll(() {
      tz.initializeTimeZones();
    });

    test('timezone database initializes and parses local and specific locations', () {
      expect(tz.timeZoneDatabase.locations.isNotEmpty, isTrue);

      final utcLocation = tz.getLocation('UTC');
      expect(utcLocation.name, equals('UTC'));

      final nowUtc = DateTime.utc(2026, 10, 6, 12, 0);
      final tzUtc = tz.TZDateTime.from(nowUtc, utcLocation);
      expect(tzUtc.year, equals(2026));
      expect(tzUtc.month, equals(10));
      expect(tzUtc.day, equals(6));
      expect(tzUtc.hour, equals(12));
    });

    test('toZonedTime converts standard DateTime to tz.TZDateTime accurately', () {
      final service = NotificationService();
      final dt = DateTime(2026, 11, 15, 9, 30);

      final zoned = service.toZonedTime(dt);
      expect(zoned.year, equals(2026));
      expect(zoned.month, equals(11));
      expect(zoned.day, equals(15));
      expect(zoned.hour, equals(9));
      expect(zoned.minute, equals(30));
    });

    test('primaryReminderChannel and subReminderChannel are properly configured', () {
      final primary = NotificationService.primaryReminderChannel;
      expect(primary.id, equals(AppConstants.primaryReminderChannelId));
      expect(primary.name, equals(AppConstants.primaryReminderChannelName));
      expect(primary.description, equals(AppConstants.primaryReminderChannelDesc));
      expect(primary.importance, equals(Importance.max));
      expect(primary.playSound, isTrue);
      expect(primary.enableVibration, isTrue);

      final sub = NotificationService.subReminderChannel;
      expect(sub.id, equals(AppConstants.subReminderChannelId));
      expect(sub.name, equals(AppConstants.subReminderChannelName));
      expect(sub.description, equals(AppConstants.subReminderChannelDesc));
      expect(sub.importance, equals(Importance.high));
      expect(sub.playSound, isTrue);
      expect(sub.enableVibration, isTrue);
    });

    test('notification tap stream handles emissions and lifecycle', () async {
      final service = NotificationService();

      expect(
        service.onNotificationTap,
        emitsInOrder(['note-id-123', null]),
      );

      // Verify stream is active
      service.dispose();
    });
  });
}
