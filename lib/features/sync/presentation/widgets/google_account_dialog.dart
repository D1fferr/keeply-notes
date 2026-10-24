import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/google_user_entity.dart';
import '../cubit/google_auth_cubit.dart';
import '../cubit/google_auth_state.dart';

/// Modal dialog displaying Google account connection status, cloud sync details,
/// and interactive Sign In / Sign Out actions.
class GoogleAccountDialog extends StatefulWidget {
  const GoogleAccountDialog({
    super.key,
    required this.authCubit,
  });

  final GoogleAuthCubit authCubit;

  static Future<void> show(BuildContext context, GoogleAuthCubit authCubit) {
    return showDialog(
      context: context,
      builder: (ctx) => GoogleAccountDialog(authCubit: authCubit),
    );
  }

  @override
  State<GoogleAccountDialog> createState() => _GoogleAccountDialogState();
}

class _GoogleAccountDialogState extends State<GoogleAccountDialog> {
  @override
  void initState() {
    super.initState();
    widget.authCubit.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.authCubit.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.authCubit.state;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.dialogBackgroundColor,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryWarmLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              color: AppColors.primaryWarmDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Google Drive Sync',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: _buildContent(context, state),
      actions: _buildActions(context, state),
    );
  }

  Widget _buildContent(BuildContext context, GoogleAuthState state) {
    if (state is GoogleAuthLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Connecting to Google...',
              style: const TextStyle(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is GoogleAuthAuthenticated) {
      return _buildAuthenticatedView(context, state.user);
    }

    if (state is GoogleAuthError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            state.message,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildUnauthenticatedView(context),
        ],
      );
    }

    return _buildUnauthenticatedView(context);
  }

  Widget _buildAuthenticatedView(BuildContext context, GoogleUserEntity user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightCardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryWarmDark,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        (user.displayName?.isNotEmpty == true
                                ? user.displayName![0]
                                : user.email[0])
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user.displayName != null && user.displayName!.isNotEmpty)
                      Text(
                        user.displayName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.reminderActive, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connected to Google Drive appDataFolder',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.primaryWarmDark, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'End-to-End Encryption key active (HKDF-SHA256)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        // Sync metrics and instant trigger
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.authCubit.isSyncing
                        ? 'Synchronizing...'
                        : widget.authCubit.lastSyncResult != null
                            ? widget.authCubit.lastSyncResult!.success
                                ? widget.authCubit.lastSyncResult!.totalChanges > 0
                                    ? 'Synced: ↑${widget.authCubit.lastSyncResult!.totalUploaded} ↓${widget.authCubit.lastSyncResult!.totalDownloaded}'
                                    : 'All items are up to date'
                                : 'Sync error: ${widget.authCubit.lastSyncResult!.errorMessage}'
                            : 'Ready to sync',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.authCubit.lastSyncResult?.success == false
                          ? Colors.red
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (widget.authCubit.lastSyncResult != null)
                    Text(
                      'Last: ${widget.authCubit.lastSyncResult!.syncedAt.toLocal().toString().substring(11, 16)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryWarmDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: widget.authCubit.isSyncing
                  ? null
                  : () async {
                      await widget.authCubit.syncNow();
                    },
              icon: widget.authCubit.isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded, size: 16),
              label: Text(widget.authCubit.isSyncing ? 'Syncing' : 'Sync Now'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect your Google Account to back up and sync notes, folders, and attachments securely across devices.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondaryLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _buildFeatureRow(
          icon: Icons.shield_outlined,
          title: 'Zero-knowledge E2E encryption',
        ),
        const SizedBox(height: 8),
        _buildFeatureRow(
          icon: Icons.folder_special_outlined,
          title: 'Hidden Google Drive AppData storage',
        ),
        const SizedBox(height: 8),
        _buildFeatureRow(
          icon: Icons.sync_rounded,
          title: 'Automatic differential sync (Last-Write-Wins)',
        ),
      ],
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryWarmDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, GoogleAuthState state) {
    if (state is GoogleAuthLoading) {
      return [];
    }

    if (state is GoogleAuthAuthenticated) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () async {
            await widget.authCubit.signOut();
          },
          child: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Later'),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryWarmDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.login_rounded, size: 18),
        label: const Text('Sign In with Google'),
        onPressed: () async {
          final success = await widget.authCubit.signIn();
          if (success && mounted) {
            // keep dialog open showing authenticated status
          }
        },
      ),
    ];
  }
}
