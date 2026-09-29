import 'package:flutter/material.dart';
import '../../domain/folder_entity.dart';
import '../cubit/folder_cubit.dart';

/// Collection of stateless dialog helpers for folder CRUD operations.
///
/// All dialogs are pure UI — they call back into [FolderCubit] on confirm.
abstract final class FolderDialogs {
  // ─── Create ──────────────────────────────────────────────────────────────

  /// Shows a dialog to create a new folder under the current navigation level.
  static Future<void> showCreate(
    BuildContext context,
    FolderCubit cubit,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Folder name',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a folder name';
              }
              if (v.trim().length > 120) {
                return 'Name must be 120 characters or fewer';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.createFolder(controller.text.trim());
    }
    controller.dispose();
  }

  // ─── Rename ───────────────────────────────────────────────────────────────

  /// Shows a dialog to rename [folder].
  static Future<void> showRename(
    BuildContext context,
    FolderCubit cubit,
    FolderEntity folder,
  ) async {
    final controller = TextEditingController(text: folder.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Folder name',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a folder name';
              }
              if (v.trim().length > 120) {
                return 'Name must be 120 characters or fewer';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.renameFolder(folder.id, controller.text.trim());
    }
    controller.dispose();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Shows a confirmation dialog before soft-deleting [folder] and its subtree.
  static Future<void> showDelete(
    BuildContext context,
    FolderCubit cubit,
    FolderEntity folder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Delete "${folder.name}" and all its subfolders?\n\n'
          'Notes inside will not be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.deleteFolder(folder.id);
    }
  }

  // ─── Move ─────────────────────────────────────────────────────────────────

  /// Shows a simple dialog to move [folder] to root level.
  ///
  /// Phase 2.2 scope: moves folder to root (Home). A full picker for arbitrary
  /// parent selection is deferred to the folder-tree picker in a later phase.
  static Future<void> showMoveToRoot(
    BuildContext context,
    FolderCubit cubit,
    FolderEntity folder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Folder'),
        content: Text(
          'Move "${folder.name}" to the top level (Home)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Move to Home'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.moveFolder(folder.id, newParentId: null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${folder.name}" moved to Home')),
        );
      }
    }
  }

  // ─── Toggle protection ────────────────────────────────────────────────────

  /// Toggles the protection flag on [folder] with an inline confirmation.
  static Future<void> showToggleProtection(
    BuildContext context,
    FolderCubit cubit,
    FolderEntity folder,
  ) async {
    final willLock = !folder.isProtected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willLock ? 'Lock Folder' : 'Remove Protection'),
        content: Text(
          willLock
              ? 'Require biometric authentication to access "${folder.name}"?'
              : 'Remove the lock from "${folder.name}"?\n\n'
                  'Its notes will become visible in lists and search.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(willLock ? 'Lock' : 'Unlock'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.setFolderProtection(folder.id, isProtected: willLock);
    }
  }
}
