import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/attachment_entity.dart';
import '../../domain/usecases/attachment_usecases.dart';
import 'encrypted_image_view.dart';

/// Full-screen image viewer with pinch-to-zoom and pan support.
class AttachmentFullscreenDialog extends StatelessWidget {
  const AttachmentFullscreenDialog({
    super.key,
    required this.attachment,
    required this.getDecryptedAttachmentBytes,
    required this.onDelete,
  });

  final AttachmentEntity attachment;
  final GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytes;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
    required AttachmentEntity attachment,
    required GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytes,
    required VoidCallback onDelete,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => AttachmentFullscreenDialog(
          attachment: attachment,
          getDecryptedAttachmentBytes: getDecryptedAttachmentBytes,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete image',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Attachment'),
                  content: const Text('Delete this encrypted image attachment permanently?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                Navigator.of(context).pop();
                onDelete();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: EncryptedImageView(
            localPath: attachment.localPath,
            getDecryptedAttachmentBytes: getDecryptedAttachmentBytes,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}
