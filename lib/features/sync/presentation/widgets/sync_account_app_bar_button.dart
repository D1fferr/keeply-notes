import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/google_auth_cubit.dart';
import '../cubit/google_auth_state.dart';
import 'google_account_dialog.dart';

/// AppBar action button that reflects Google Drive account connection status
/// and opens [GoogleAccountDialog] when tapped.
class SyncAccountAppBarButton extends StatefulWidget {
  const SyncAccountAppBarButton({
    super.key,
    required this.authCubit,
  });

  final GoogleAuthCubit authCubit;

  @override
  State<SyncAccountAppBarButton> createState() => _SyncAccountAppBarButtonState();
}

class _SyncAccountAppBarButtonState extends State<SyncAccountAppBarButton> {
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

    if (state is GoogleAuthLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (state is GoogleAuthAuthenticated) {
      final user = state.user;
      return IconButton(
        tooltip: 'Google Drive Sync (${user.email})',
        icon: Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (user.photoUrl != null)
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(user.photoUrl!),
              )
            else
              const Icon(Icons.cloud_done_rounded, color: AppColors.primaryWarmDark),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.reminderActive,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).appBarTheme.backgroundColor ??
                      Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
        onPressed: () => GoogleAccountDialog.show(context, widget.authCubit),
      );
    }

    return IconButton(
      tooltip: 'Sign in to sync with Google Drive',
      icon: const Icon(Icons.cloud_outlined),
      onPressed: () => GoogleAccountDialog.show(context, widget.authCubit),
    );
  }
}
