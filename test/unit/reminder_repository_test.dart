import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/database/app_database.dart';
import 'package:keeply_notes/core/services/notification_service.dart';
import 'package:keeply_notes/features/reminders/data/datasources/reminder_local_data_source_impl.dart';
import 'package:keeply_notes/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:keeply_notes/features/reminders/domain/reminder_entity.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationService extends NotificationService {
  final List<Map<String, dynamic>> scheduledCalls = [];
  final List<int> cancelledIds = [];

  @override
  tz.TZDateTime toZonedTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  @override
  Future<void> scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    bool isSubReminder = false,
  }) async {
    scheduledCalls.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'payload': payload,
      'isSubReminder': isSubReminder,
    });
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
  }
}

void main() {
  group('ReminderRepository & ReminderLocalDataSource Unit Tests (Task 4.2)', () {
    late AppDatabase db;
    late ReminderLocalDataSourceImpl dataSource;
    late FakeNotificationService fakeNotifications;
    late ReminderRepositoryImpl repository;

    const noteId = 'test-note-1';

    setUpAll(() {
      tz.initializeTimeZones();
    });

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Insert a dummy note first to satisfy foreign key constraints if foreign keys are enabled
      await db.into(db.notes).insert(
            NotesCompanion.insert(
              id: noteId,
              title: 'Test Note Title',
              contentJson: '[]',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      dataSource = ReminderLocalDataSourceImpl(db);
      fakeNotifications = FakeNotificationService();
      repository = ReminderRepositoryImpl(
        dataSource: dataSource,
        notificationService: fakeNotifications,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('setReminder creates a new reminder and schedules native alarm', () async {
      final futureDate = DateTime.now().add(const Duration(days: 2));

      final reminder = await repository.setReminder(
        noteId: noteId,
        startDateTime: futureDate,
        repeatType: RepeatType.daily,
        isEnabled: true,
        noteTitle: 'Test Note Title',
      );

      expect(reminder.id, isNotEmpty);
      expect(reminder.noteId, equals(noteId));
      expect(reminder.repeatType, equals(RepeatType.daily));
      expect(reminder.isEnabled, isTrue);

      // Verify notification scheduled
      expect(fakeNotifications.scheduledCalls.length, equals(1));
      final call = fakeNotifications.scheduledCalls.first;
      expect(call['title'], equals('Test Note Title'));
      expect(call['payload'], equals(noteId));
      expect(call['isSubReminder'], isFalse);

      // Verify DB retrieval
      final fromDb = await repository.getReminderByNoteId(noteId);
      expect(fromDb, isNotNull);
      expect(fromDb!.id, equals(reminder.id));
    });

    test('setReminder upserts if reminder for note already exists', () async {
      final date1 = DateTime.now().add(const Duration(days: 1));
      final date2 = DateTime.now().add(const Duration(days: 3));

      final first = await repository.setReminder(
        noteId: noteId,
        startDateTime: date1,
        repeatType: RepeatType.none,
        isEnabled: true,
      );

      final second = await repository.setReminder(
        noteId: noteId,
        startDateTime: date2,
        repeatType: RepeatType.weekly,
        isEnabled: true,
      );

      expect(second.id, equals(first.id));
      expect(second.repeatType, equals(RepeatType.weekly));
      expect(fakeNotifications.scheduledCalls.length, equals(2));
    });

    test('toggleReminderEnabled pauses notification alarm when false and reschedules when true', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));

      final reminder = await repository.setReminder(
        noteId: noteId,
        startDateTime: futureDate,
        repeatType: RepeatType.daily,
        isEnabled: true,
      );

      // Disable reminder
      final disabled = await repository.toggleReminderEnabled(reminder.id, false);
      expect(disabled.isEnabled, isFalse);
      expect(fakeNotifications.cancelledIds.length, equals(1));

      // Re-enable reminder
      final enabled = await repository.toggleReminderEnabled(reminder.id, true);
      expect(enabled.isEnabled, isTrue);
      // Scheduled calls: initial + re-enable = 2
      expect(fakeNotifications.scheduledCalls.length, equals(2));
    });

    test('deleteReminder cancels notification and removes reminder from DB', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));

      final reminder = await repository.setReminder(
        noteId: noteId,
        startDateTime: futureDate,
        repeatType: RepeatType.none,
      );

      await repository.deleteReminder(reminder.id);

      expect(fakeNotifications.cancelledIds.length, equals(1));
      final fetched = await repository.getReminderById(reminder.id);
      expect(fetched, isNull);
    });

    test('watchReminderForNote provides reactive stream updates', () async {
      final stream = repository.watchReminderForNote(noteId);
      final futureDate = DateTime.now().add(const Duration(days: 1));

      expect(
        stream,
        emitsInOrder([
          isNull, // initial state before insert
          isA<ReminderEntity>().having((r) => r.isEnabled, 'isEnabled', isTrue),
          isA<ReminderEntity>().having((r) => r.isEnabled, 'isEnabled', isFalse),
        ]),
      );

      // Create reminder
      final rem = await repository.setReminder(
        noteId: noteId,
        startDateTime: futureDate,
        repeatType: RepeatType.daily,
      );

      // Toggle
      await repository.toggleReminderEnabled(rem.id, false);
    });

    test('rescheduleAllActiveReminders reschedules all active reminders at once', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));

      await repository.setReminder(
        noteId: noteId,
        startDateTime: futureDate,
        repeatType: RepeatType.daily,
        isEnabled: true,
      );

      fakeNotifications.scheduledCalls.clear();

      await repository.rescheduleAllActiveReminders();

      expect(fakeNotifications.scheduledCalls.length, equals(1));
    });
  });
}
