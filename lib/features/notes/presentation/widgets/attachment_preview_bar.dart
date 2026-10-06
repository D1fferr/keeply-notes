import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/attachment_entity.dart';
import '../../domain/usecases/attachment_usecases.dart';
import 'attachment_thumbnail.dart';

/// Horizontal preview bar showing all encrypted media attachments for a note.
class AttachmentPreviewBar extends StatelessWidget {
  const AttachmentPreviewBar({
    super.key,
    required this.attachments,
    required this.getDecryptedAttachmentBytes,
    required this.onDeleteAttachment,
    required this.onAddAttachment,
  });

  final List<AttachmentEntity> attachments;
  final GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytes;
  final void Function(AttachmentEntity attachment) onDeleteAttachment;
  final VoidCallback onAddAttachment;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attachments (${attachments.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              InkWell(
                onTap: onAddAttachment,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.primaryWarmDark),
                      const SizedBox(width: 4),
                      Text(
                        'Add image',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryWarmDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final item = attachments[index];
              return AttachmentThumbnail(
                attachment: item,
                getDecryptedAttachmentBytes: getDecryptedAttachmentBytes,
                onDelete: () => onDeleteAttachment(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
