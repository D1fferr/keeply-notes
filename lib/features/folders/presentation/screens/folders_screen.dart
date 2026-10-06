import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../notes/domain/note_entity.dart';
import '../../../notes/domain/usecases/attachment_usecases.dart';
import '../../../notes/domain/usecases/note_crud_usecases.dart';
import '../../../notes/presentation/cubit/notes_cubit.dart';
import '../../../notes/presentation/cubit/notes_state.dart';
import '../../../notes/presentation/screens/note_editor_screen.dart';
import '../../../notes/presentation/widgets/note_card.dart';
import '../../domain/folder_entity.dart';
import '../cubit/folder_cubit.dart';
import '../cubit/folder_state.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/folder_dialogs.dart';
import '../widgets/folder_list_tile.dart';

/// Main screen for browsing and managing the multi-level folder hierarchy and notes.
///
/// Handles:
/// - Root / subfolder navigation with reactive Drift streams
/// - Breadcrumb trail with tap-to-navigate support
/// - Displaying notes belonging to the active folder level
/// - Android back-button interception for hierarchical back-navigation
/// - Dual FAB / action options for creating notes and folders
/// - Full note editing and creation flow via [NoteEditorScreen]
class FoldersScreen extends StatefulWidget {
  const FoldersScreen({
    super.key,
    required this.folderCubit,
    required this.notesCubit,
    required this.createNoteUseCase,
    required this.updateNoteUseCase,
    required this.deleteNoteUseCase,
    required this.saveAttachmentUseCase,
    required this.getDecryptedAttachmentBytesUseCase,
    required this.watchNoteAttachmentsUseCase,
    required this.deleteAttachmentUseCase,
  });

  final FolderCubit folderCubit;
  final NotesCubit notesCubit;
  final CreateNoteUseCase createNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;

  final SaveAttachmentUseCase saveAttachmentUseCase;
  final GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytesUseCase;
  final WatchNoteAttachmentsUseCase watchNoteAttachmentsUseCase;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  FolderCubit get _folderCubit => widget.folderCubit;
  NotesCubit get _notesCubit => widget.notesCubit;

  String? _lastFolderId;

  @override
  void initState() {
    super.initState();
    _folderCubit.addListener(_onFolderStateChanged);
    _notesCubit.addListener(_onNotesStateChanged);
  }

  void _onFolderStateChanged() {
    if (!mounted) return;

    final state = _folderCubit.state;
    if (state is FolderLoaded && state.currentFolderId != _lastFolderId) {
      _lastFolderId = state.currentFolderId;
      _notesCubit.loadNotesForFolder(_lastFolderId);
    }
    setState(() {});
  }

  void _onNotesStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _folderCubit.removeListener(_onFolderStateChanged);
    _notesCubit.removeListener(_onNotesStateChanged);
    super.dispose();
  }

  // ─── Note Editor Navigation ───────────────────────────────────────────────

  void _openNoteEditor({NoteEntity? note}) {
    final folderState = _folderCubit.state;
    final currentFolderId =
        folderState is FolderLoaded ? folderState.currentFolderId : null;
    final currentFolderName =
        folderState is FolderLoaded && folderState.breadcrumb.length > 1
            ? folderState.breadcrumb.last.name
            : null;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => NoteEditorScreen(
          note: note,
          folderId: currentFolderId,
          folderName: currentFolderName,
          createNote: widget.createNoteUseCase,
          updateNote: widget.updateNoteUseCase,
          deleteNote: widget.deleteNoteUseCase,
          saveAttachment: widget.saveAttachmentUseCase,
          getDecryptedAttachmentBytes: widget.getDecryptedAttachmentBytesUseCase,
          watchNoteAttachments: widget.watchNoteAttachmentsUseCase,
          deleteAttachment: widget.deleteAttachmentUseCase,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _folderCubit.navigateBack();
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
    final state = _folderCubit.state;
    final isAtRoot = state is FolderLoaded && state.breadcrumb.length <= 1;

    return AppBar(
      leading: isAtRoot
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => _folderCubit.navigateBack(),
              tooltip: 'Back',
            ),
      title: const Text('Keeply Notes'),
      actions: [
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
    final state = _folderCubit.state;
    if (state is! FolderLoaded) return null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(36),
      child: Align(
        alignment: Alignment.centerLeft,
        child: BreadcrumbBar(
          breadcrumb: state.breadcrumb,
          onCrumbTap: _folderCubit.navigateToBreadcrumb,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final folderState = _folderCubit.state;
    final notesState = _notesCubit.state;

    if (folderState is FolderLoading && notesState is NotesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (folderState is FolderError) {
      return _buildError(context, folderState.message);
    }
    if (notesState is NotesError) {
      return _buildError(context, notesState.message);
    }

    final folders =
        folderState is FolderLoaded ? folderState.folders : <FolderEntity>[];
    final notes =
        notesState is NotesLoaded ? notesState.notes : <NoteEntity>[];

    if (folders.isEmpty && notes.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        // Folders Section
        if (folders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Folders (${folders.length})',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final folder = folders[index];
                return FolderListTile(
                  key: ValueKey(folder.id),
                  folder: folder,
                  onTap: () => _folderCubit.openFolder(folder),
                  onRename: () =>
                      FolderDialogs.showRename(context, _folderCubit, folder),
                  onMove: () =>
                      FolderDialogs.showMoveToRoot(context, _folderCubit, folder),
                  onToggleProtection: () => FolderDialogs.showToggleProtection(
                      context, _folderCubit, folder),
                  onDelete: () =>
                      FolderDialogs.showDelete(context, _folderCubit, folder),
                );
              },
              childCount: folders.length,
            ),
          ),
        ],

        // Notes Section
        if (notes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Notes (${notes.length})',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final note = notes[index];
                return NoteCard(
                  key: ValueKey(note.id),
                  note: note,
                  onTap: () => _openNoteEditor(note: note),
                  onTogglePin: () => _notesCubit.togglePin(note.id),
                  onDelete: () => _notesCubit.deleteNote(note.id),
                );
              },
              childCount: notes.length,
            ),
          ),
        ],

        // Bottom padding for FAB clearance
        const SliverToBoxAdapter(
          child: SizedBox(height: 88),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
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
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
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
            const Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: AppColors.primaryWarm,
            ),
            const SizedBox(height: 16),
            Text(
              'No notes or folders here yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to write a note or create a folder.',
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

  Widget _buildFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Secondary action: New Folder
        FloatingActionButton.small(
          heroTag: 'fab_folder',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: AppColors.primaryWarmDark,
          elevation: 2,
          onPressed: () => FolderDialogs.showCreate(context, _folderCubit),
          tooltip: 'New folder',
          child: const Icon(Icons.create_new_folder_rounded, size: 20),
        ),
        const SizedBox(height: 12),
        // Primary action: New Note
        FloatingActionButton.extended(
          heroTag: 'fab_note',
          onPressed: () => _openNoteEditor(),
          tooltip: 'New note',
          icon: const Icon(Icons.edit_note_rounded, size: 24),
          label: const Text(
            'New Note',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
