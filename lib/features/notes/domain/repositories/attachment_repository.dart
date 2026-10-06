import 'dart:typed_data';
import '../attachment_entity.dart';

/// Contract for managing media attachments and their encrypted storage on disk.
abstract interface class AttachmentRepository {
  /// Encrypts and saves [rawBytes] as an AES-256 encrypted file in the app's documents directory,
  /// and creates a corresponding database record linked to [noteId].
  Future<AttachmentEntity> saveAttachment({
    required String noteId,
    required Uint8List rawBytes,
    String fileExtension = 'jpg',
  });

  /// Reads and decrypts the encrypted media file at [localPath] into raw bytes in memory.
  Future<Uint8List> getDecryptedAttachmentBytes(String localPath);

  /// Retrieves all attachments linked to [noteId].
  Future<List<AttachmentEntity>> getAttachmentsForNote(String noteId);

  /// Emits real-time updates for attachments linked to [noteId].
  Stream<List<AttachmentEntity>> watchAttachmentsForNote(String noteId);

  /// Deletes an attachment: removes its database record and deletes its encrypted file from disk.
  Future<void> deleteAttachment(String id);

  /// Deletes all attachments for [noteId], including their encrypted files from disk.
  Future<void> deleteAttachmentsForNote(String noteId);
}
