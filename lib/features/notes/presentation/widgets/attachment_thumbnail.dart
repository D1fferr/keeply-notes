import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/attachment_entity.dart';
import '../../domain/usecases/attachment_usecases.dart';
import 'attachment_fullscreen_dialog.dart';
import 'encrypted_image_view.dart';

/// Thumbnail card rendering an attached encrypted image.
class AttachmentThumbnail extends StatelessWidget {
  const AttachmentThumbnail({
    super.key,
    required this.attachment,
    required this.getDecryptedAttachmentBytes,
    required this.onDelete,
    this.size = 100,
  });

  final AttachmentEntity attachment;
  final GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytes;
  final VoidCallback onDelete;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => AttachmentFullscreenDialog.show(
            context,
            attachment: attachment,
            getDecryptedAttachmentBytes: getDecryptedAttachmentBytes,
            onDelete: onDelete,
          ),
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(right: 10, top: 6, bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryWarm.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: EncryptedImageView(
              localPath: attachment.localPath,
              getDecryptedAttachmentBytes: getDecryptedAttachmentBytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Quick delete button
        Positioned(
          top: 0,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
