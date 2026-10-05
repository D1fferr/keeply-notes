import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/folder_entity.dart';
import '../cubit/folder_cubit.dart';
import '../cubit/folder_state.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/folder_dialogs.dart';
import '../widgets/folder_list_tile.dart';

/// Main screen for browsing and managing the multi-level folder hierarchy.
///
/// Handles:
/// - Root / subfolder navigation with reactive Drift streams
/// - Breadcrumb trail with tap-to-navigate support
/// - Android back-button interception for folder back-navigation
/// - FAB for creating a new folder at the current level
/// - Per-folder context menu (rename, move, lock, delete)
class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key, required this.cubit});

  final FolderCubit cubit;

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  FolderCubit get _cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    _cubit.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cubit.removeListener(_onStateChanged);
    super.dispose();
  }

  // ─── Back navigation ──────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    return !_cubit.navigateBack();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _cubit.navigateBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final state = _cubit.state;
    final isAtRoot = state is FolderLoaded && state.breadcrumb.length <= 1;

    return AppBar(
      leading: isAtRoot
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => _cubit.navigateBack(),
              tooltip: 'Back',
            ),
      title: const Text('Folders'),
      actions: [
        // Placeholder for future search action
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {},
          tooltip: 'Search (coming soon)',
        ),
      ],
      bottom: _buildBreadcrumbBottom(context),
    );
  }

  PreferredSizeWidget? _buildBreadcrumbBottom(BuildContext context) {
    final state = _cubit.state;
    if (state is! FolderLoaded) return null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(36),
      child: Align(
        alignment: Alignment.centerLeft,
        child: BreadcrumbBar(
          breadcrumb: state.breadcrumb,
          onCrumbTap: _cubit.navigateToBreadcrumb,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = _cubit.state;

    return switch (state) {
      FolderInitial() => const SizedBox.shrink(),
      FolderLoading() => const Center(child: CircularProgressIndicator()),
      FolderError() => _buildError(context, state),
      FolderLoaded() => _buildFolderList(context, state),
    };
  }

  Widget _buildError(BuildContext context, FolderError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(BuildContext context, FolderLoaded state) {
    if (state.folders.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: state.folders.length,
      itemBuilder: (ctx, index) {
        final folder = state.folders[index];
        return FolderListTile(
          key: ValueKey(folder.id),
          folder: folder,
          onTap: () => _cubit.openFolder(folder),
          onRename: () => FolderDialogs.showRename(context, _cubit, folder),
          onMove: () => FolderDialogs.showMoveToRoot(context, _cubit, folder),
          onToggleProtection: () =>
              FolderDialogs.showToggleProtection(context, _cubit, folder),
          onDelete: () => FolderDialogs.showDelete(context, _cubit, folder),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: AppColors.primaryWarm,
            ),
            const SizedBox(height: 16),
            Text(
              'No folders here yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first folder.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  FloatingActionButton _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => FolderDialogs.showCreate(context, _cubit),
      tooltip: 'New folder',
      child: const Icon(Icons.create_new_folder_rounded),
    );
  }
}
