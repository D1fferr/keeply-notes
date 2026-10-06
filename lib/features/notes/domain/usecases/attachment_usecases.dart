import 'dart:typed_data';
import '../attachment_entity.dart';
import '../repositories/attachment_repository.dart';

/// Encrypts and saves an image/media attachment for a note.
class SaveAttachmentUseCase {
  const SaveAttachmentUseCase(this._repository);

  final AttachmentRepository _repository;

  Future<AttachmentEntity> call({
    required String noteId,
    required Uint8List rawBytes,
    String fileExtension = 'jpg',
  }) =>
      _repository.saveAttachment(
        noteId: noteId,
        rawBytes: rawBytes,
        fileExtension: fileExtension,
      );
}

/// Decrypts encrypted file bytes for previewing/rendering.
class GetDecryptedAttachmentBytesUseCase {
  const GetDecryptedAttachmentBytesUseCase(this._repository);

  final AttachmentRepository _repository;

  Future<Uint8List> call(String localPath) =>
      _repository.getDecryptedAttachmentBytes(localPath);
}

/// Retrieves all attachments for a specific note.
class GetAttachmentsForNoteUseCase {
  const GetAttachmentsForNoteUseCase(this._repository);

  final AttachmentRepository _repository;

  Future<List<AttachmentEntity>> call(String noteId) =>
      _repository.getAttachmentsForNote(noteId);
}

/// Watches attachments for a specific note in real time.
class WatchNoteAttachmentsUseCase {
  const WatchNoteAttachmentsUseCase(this._repository);

  final AttachmentRepository _repository;

  Stream<List<AttachmentEntity>> call(String noteId) =>
      _repository.watchAttachmentsForNote(noteId);
}

/// Deletes an attachment and its encrypted file on disk.
class DeleteAttachmentUseCase {
  const DeleteAttachmentUseCase(this._repository);

  final AttachmentRepository _repository;

  Future<void> call(String id) => _repository.deleteAttachment(id);
}
