import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/reminder_entity.dart';
import 'reminder_local_data_source.dart';

/// Drift-backed implementation of [ReminderLocalDataSource].
class ReminderLocalDataSourceImpl implements ReminderLocalDataSource {
  ReminderLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  ReminderEntity _toEntity(ReminderData data) => ReminderEntity(
        id: data.id,
        noteId: data.noteId,
        startDateTime: data.startDateTime,
        repeatType: RepeatType.fromString(data.repeatType),
        customDaysInterval: data.customDaysInterval,
        isEnabled: data.isEnabled,
      );

  @override
  Future<ReminderEntity?> getReminderByNoteId(String noteId) async {
    final row = await (_db.select(_db.reminders)
          ..where((r) => r.noteId.equals(noteId)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<ReminderEntity?> getReminderById(String id) async {
    final row = await (_db.select(_db.reminders)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<ReminderEntity>> getAllActiveReminders() async {
    final rows = await (_db.select(_db.reminders)
          ..where((r) => r.isEnabled.equals(true)))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<ReminderEntity?> watchReminderByNoteId(String noteId) {
    return (_db.select(_db.reminders)
          ..where((r) => r.noteId.equals(noteId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toEntity(row));
  }

  @override
  Future<ReminderEntity> upsertReminder({
    required String id,
    required String noteId,
    required DateTime startDateTime,
    required String repeatType,
    int? customDaysInterval,
    required bool isEnabled,
  }) async {
    final existing = await getReminderByNoteId(noteId);

    if (existing != null) {
      await (_db.update(_db.reminders)..where((r) => r.id.equals(existing.id)))
          .write(
        RemindersCompanion(
          startDateTime: Value(startDateTime),
          repeatType: Value(repeatType),
          customDaysInterval: Value(customDaysInterval),
          isEnabled: Value(isEnabled),
        ),
      );
      AppLogger.debug('ReminderLocalDataSource: updated reminder ${existing.id} for note $noteId');
      return (await getReminderById(existing.id))!;
    } else {
      final companion = RemindersCompanion(
        id: Value(id),
        noteId: Value(noteId),
        startDateTime: Value(startDateTime),
        repeatType: Value(repeatType),
        customDaysInterval: Value(customDaysInterval),
        isEnabled: Value(isEnabled),
      );

      await _db.into(_db.reminders).insert(companion);
      AppLogger.debug('ReminderLocalDataSource: inserted reminder $id for note $noteId');
      return (await getReminderById(id))!;
    }
  }

  @override
  Future<ReminderEntity> updateReminderEnabled(String id, bool isEnabled) async {
    await (_db.update(_db.reminders)..where((r) => r.id.equals(id))).write(
      RemindersCompanion(isEnabled: Value(isEnabled)),
    );
    AppLogger.debug('ReminderLocalDataSource: set isEnabled=$isEnabled on reminder $id');
    return (await getReminderById(id))!;
  }

  @override
  Future<void> deleteReminder(String id) async {
    await (_db.delete(_db.reminders)..where((r) => r.id.equals(id))).go();
    AppLogger.debug('ReminderLocalDataSource: deleted reminder $id');
  }

  @override
  Future<void> deleteReminderByNoteId(String noteId) async {
    await (_db.delete(_db.reminders)..where((r) => r.noteId.equals(noteId))).go();
    AppLogger.debug('ReminderLocalDataSource: deleted reminder for note $noteId');
  }

  // ─── Sub-reminders ──────────────────────────────────────────────────────────

  SubReminderEntity _toSubEntity(SubReminderData data) => SubReminderEntity(
        id: data.id,
        reminderId: data.reminderId,
        type: SubReminderType.fromString(data.type),
        offsetMinutes: data.offsetMinutes,
        exactTime: data.exactTime,
      );

  @override
  Future<List<SubReminderEntity>> getSubRemindersByReminderId(
      String reminderId) async {
    final rows = await (_db.select(_db.subReminders)
          ..where((s) => s.reminderId.equals(reminderId)))
        .get();
    return rows.map(_toSubEntity).toList();
  }

  @override
  Stream<List<SubReminderEntity>> watchSubRemindersByReminderId(
      String reminderId) {
    return (_db.select(_db.subReminders)
          ..where((s) => s.reminderId.equals(reminderId)))
        .watch()
        .map((rows) => rows.map(_toSubEntity).toList());
  }

  @override
  Future<SubReminderEntity> insertSubReminder({
    required String id,
    required String reminderId,
    required String type,
    int? offsetMinutes,
    String? exactTime,
  }) async {
    final companion = SubRemindersCompanion(
      id: Value(id),
      reminderId: Value(reminderId),
      type: Value(type),
      offsetMinutes: Value(offsetMinutes),
      exactTime: Value(exactTime),
    );

    await _db.into(_db.subReminders).insert(companion);
    AppLogger.debug('ReminderLocalDataSource: inserted sub-reminder $id for reminder $reminderId');

    return SubReminderEntity(
      id: id,
      reminderId: reminderId,
      type: SubReminderType.fromString(type),
      offsetMinutes: offsetMinutes,
      exactTime: exactTime,
    );
  }

  @override
  Future<void> replaceSubReminders({
    required String reminderId,
    required List<SubReminderEntity> subReminders,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.subReminders)
            ..where((s) => s.reminderId.equals(reminderId)))
          .go();

      for (final sub in subReminders) {
        await _db.into(_db.subReminders).insert(
              SubRemindersCompanion(
                id: Value(sub.id),
                reminderId: Value(reminderId),
                type: Value(sub.type.toDbString()),
                offsetMinutes: Value(sub.offsetMinutes),
                exactTime: Value(sub.exactTime),
              ),
            );
      }
    });
    AppLogger.debug('ReminderLocalDataSource: replaced ${subReminders.length} sub-reminders for reminder $reminderId');
  }

  @override
  Future<void> deleteSubReminder(String id) async {
    await (_db.delete(_db.subReminders)..where((s) => s.id.equals(id))).go();
    AppLogger.debug('ReminderLocalDataSource: deleted sub-reminder $id');
  }

  @override
  Future<void> deleteSubRemindersByReminderId(String reminderId) async {
    await (_db.delete(_db.subReminders)
          ..where((s) => s.reminderId.equals(reminderId)))
        .go();
    AppLogger.debug('ReminderLocalDataSource: deleted sub-reminders for reminder $reminderId');
  }
}
