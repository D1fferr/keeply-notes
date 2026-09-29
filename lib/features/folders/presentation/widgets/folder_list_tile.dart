import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/folder_entity.dart';

/// A single row in the folder list.
///
/// Tapping opens the folder; long-pressing (or tapping the trailing "⋮")
/// shows the context menu with rename, move, toggle-lock, and delete actions.
class FolderListTile extends StatelessWidget {
  const FolderListTile({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onRename,
    required this.onMove,
    required this.onToggleProtection,
    required this.onDelete,
  });

  final FolderEntity folder;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onToggleProtection;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Folder icon with optional lock indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 28,
                    color: AppColors.primaryWarmDark,
                  ),
                  if (folder.isProtected)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.protectedLock,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Folder name
              Expanded(
                child: Text(
                  folder.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isLight
                        ? AppColors.textPrimaryLight
                        : AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Context menu button
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: isLight
                      ? AppColors.textSecondaryLight
                      : AppColors.textSecondaryDark,
                ),
                onPressed: () => _showContextMenu(context),
                tooltip: 'More options',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Folder name header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded,
                      color: AppColors.primaryWarmDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.drive_file_rename_outline_rounded,
              label: 'Rename',
              onTap: () {
                Navigator.of(ctx).pop();
                onRename();
              },
            ),
            _MenuItem(
              icon: Icons.drive_file_move_rounded,
              label: 'Move',
              onTap: () {
                Navigator.of(ctx).pop();
                onMove();
              },
            ),
            _MenuItem(
              icon: folder.isProtected
                  ? Icons.lock_open_rounded
                  : Icons.lock_rounded,
              label: folder.isProtected ? 'Remove protection' : 'Lock folder',
              onTap: () {
                Navigator.of(ctx).pop();
                onToggleProtection();
              },
            ),
            _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Internal helper for context menu rows.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
