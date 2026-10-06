import '../../domain/attachment_entity.dart';

/// Contract for low-level database operations on attachments.
abstract interface class AttachmentLocalDataSource {
  Future<AttachmentEntity> insertAttachment({
    required String id,
    required String noteId,
    required String localPath,
    required int fileSize,
  });

  Future<AttachmentEntity?> getAttachmentById(String id);

  Future<List<AttachmentEntity>> getAttachmentsForNote(String noteId);

  Stream<List<AttachmentEntity>> watchAttachmentsForNote(String noteId);

  Future<void> deleteAttachment(String id);

  Future<void> deleteAttachmentsForNote(String noteId);
}
