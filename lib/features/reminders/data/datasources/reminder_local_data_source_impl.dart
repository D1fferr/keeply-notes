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
}
