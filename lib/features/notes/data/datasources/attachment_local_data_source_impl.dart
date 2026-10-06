import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/attachment_entity.dart';
import 'attachment_local_data_source.dart';

/// Drift-backed implementation of [AttachmentLocalDataSource].
class AttachmentLocalDataSourceImpl implements AttachmentLocalDataSource {
  AttachmentLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  AttachmentEntity _toEntity(AttachmentData data) => AttachmentEntity(
        id: data.id,
        noteId: data.noteId,
        localPath: data.localPath,
        fileSize: data.fileSize,
      );

  @override
  Future<AttachmentEntity> insertAttachment({
    required String id,
    required String noteId,
    required String localPath,
    required int fileSize,
  }) async {
    final companion = AttachmentsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      localPath: Value(localPath),
      fileSize: Value(fileSize),
    );

    await _db.into(_db.attachments).insert(companion);
    AppLogger.debug('AttachmentLocalDataSource: inserted attachment $id for note $noteId');

    final row = await (_db.select(_db.attachments)..where((a) => a.id.equals(id))).getSingle();
    return _toEntity(row);
  }

  @override
  Future<AttachmentEntity?> getAttachmentById(String id) async {
    final row = await (_db.select(_db.attachments)..where((a) => a.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<AttachmentEntity>> getAttachmentsForNote(String noteId) async {
    final rows = await (_db.select(_db.attachments)..where((a) => a.noteId.equals(noteId))).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<AttachmentEntity>> watchAttachmentsForNote(String noteId) {
    return (_db.select(_db.attachments)..where((a) => a.noteId.equals(noteId)))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<void> deleteAttachment(String id) async {
    await (_db.delete(_db.attachments)..where((a) => a.id.equals(id))).go();
    AppLogger.debug('AttachmentLocalDataSource: deleted attachment $id');
  }

  @override
  Future<void> deleteAttachmentsForNote(String noteId) async {
    await (_db.delete(_db.attachments)..where((a) => a.noteId.equals(noteId))).go();
    AppLogger.debug('AttachmentLocalDataSource: deleted all attachments for note $noteId');
  }
}
