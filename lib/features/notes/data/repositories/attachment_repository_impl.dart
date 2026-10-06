import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/attachment_entity.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../datasources/attachment_local_data_source.dart';

/// Concrete implementation of [AttachmentRepository].
///
/// Encrypts local media files on disk using AES-256 stream encryption and maintains
/// references in the encrypted SQLite database.
class AttachmentRepositoryImpl implements AttachmentRepository {
  AttachmentRepositoryImpl({
    required AttachmentLocalDataSource dataSource,
    required EncryptionService encryptionService,
    required SecureStorageService secureStorageService,
    Future<Directory> Function()? getDocumentsDirectory,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _encryptionService = encryptionService,
        _secureStorageService = secureStorageService,
        _getDocumentsDirectory = getDocumentsDirectory ?? getApplicationDocumentsDirectory,
        _uuid = uuid ?? const Uuid();

  final AttachmentLocalDataSource _dataSource;
  final EncryptionService _encryptionService;
  final SecureStorageService _secureStorageService;
  final Future<Directory> Function() _getDocumentsDirectory;
  final Uuid _uuid;

  Future<Directory> _getAttachmentsDirectory() async {
    final docsDir = await _getDocumentsDirectory();
    final attachmentsDir = Directory(p.join(docsDir.path, AppConstants.attachmentsDirectoryName));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  @override
  Future<AttachmentEntity> saveAttachment({
    required String noteId,
    required Uint8List rawBytes,
    String fileExtension = 'jpg',
  }) async {
    final attachmentId = _uuid.v4();
    final key = await _secureStorageService.getOrCreateAttachmentKey();

    // Encrypt raw media bytes using AES-256 stream encryption
    final encryptedBytes = _encryptionService.encryptBytes(rawBytes, key);

    // Save encrypted binary blob to app storage
    final attachmentsDir = await _getAttachmentsDirectory();
    final encryptedFileName = '$attachmentId.enc';
    final targetFile = File(p.join(attachmentsDir.path, encryptedFileName));

    await targetFile.writeAsBytes(encryptedBytes, flush: true);
    AppLogger.info('AttachmentRepository: encrypted and saved attachment to ${targetFile.path} (${encryptedBytes.length} bytes)');

    // Save record to SQLite database
    return _dataSource.insertAttachment(
      id: attachmentId,
      noteId: noteId,
      localPath: targetFile.path,
      fileSize: rawBytes.length,
    );
  }

  @override
  Future<Uint8List> getDecryptedAttachmentBytes(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw FileSystemException('Encrypted attachment file not found', localPath);
    }

    final key = await _secureStorageService.getOrCreateAttachmentKey();
    return _encryptionService.decryptFile(
      encryptedFile: file,
      base64Key: key,
    );
  }

  @override
  Future<List<AttachmentEntity>> getAttachmentsForNote(String noteId) =>
      _dataSource.getAttachmentsForNote(noteId);

  @override
  Stream<List<AttachmentEntity>> watchAttachmentsForNote(String noteId) =>
      _dataSource.watchAttachmentsForNote(noteId);

  @override
  Future<void> deleteAttachment(String id) async {
    final attachment = await _dataSource.getAttachmentById(id);
    if (attachment != null) {
      final file = File(attachment.localPath);
      if (await file.exists()) {
        try {
          await file.delete();
          AppLogger.info('AttachmentRepository: deleted encrypted file ${file.path}');
        } catch (e, st) {
          AppLogger.warning('Failed to delete attachment file from disk: $e\n$st');
        }
      }
    }
    await _dataSource.deleteAttachment(id);
  }

  @override
  Future<void> deleteAttachmentsForNote(String noteId) async {
    final attachments = await _dataSource.getAttachmentsForNote(noteId);
    for (final attachment in attachments) {
      final file = File(attachment.localPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    await _dataSource.deleteAttachmentsForNote(noteId);
  }
}
