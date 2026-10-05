import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/note_entity.dart';
import '../../domain/usecases/note_crud_usecases.dart';
import '../utils/quill_delta_helper.dart';
import '../widgets/note_formatting_toolbar.dart';

/// Full-screen rich text note editor.
///
/// Features:
/// - Title editing with large modern typography
/// - WYSIWYG Delta-based rich text editing via `flutter_quill`
/// - Custom minimalist formatting toolbar
/// - Pin/unpin toggle
/// - Automatic save on exit if modified
/// - Explicit save checkmark with feedback
/// - Delete note action from context menu
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.note,
    this.folderId,
    this.folderName,
    required this.createNote,
    required this.updateNote,
    required this.deleteNote,
    this.onNoteSaved,
  });

  /// Existing note to edit, or `null` to create a new note.
  final NoteEntity? note;

  /// Folder where the note is placed (defaults to existing note's folder if null).
  final String? folderId;

  /// Human-readable folder name for display in the app bar.
  final String? folderName;

  final CreateNoteUseCase createNote;
  final UpdateNoteUseCase updateNote;
  final DeleteNoteUseCase deleteNote;

  /// Optional callback invoked after a successful save.
  final void Function(NoteEntity savedNote)? onNoteSaved;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _editorFocusNode;
  late final ScrollController _scrollController;

  NoteEntity? _currentNote;
  late bool _isPinned;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _isPinned = widget.note?.isPinned ?? false;

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _titleFocusNode = FocusNode();
    _editorFocusNode = FocusNode();
    _scrollController = ScrollController();

    // Initialize QuillController with note Delta JSON or blank doc
    final doc = QuillDeltaHelper.parseDocument(widget.note?.contentJson);
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);

    // Auto-focus title if creating a new note
    if (widget.note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocusNode.requestFocus();
      });
    }
  }

  void _onContentChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onContentChanged);
    _quillController.removeListener(_onContentChanged);
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Save logic ───────────────────────────────────────────────────────────

  Future<bool> _saveNote() async {
    final title = _titleController.text.trim();
    final isContentEmpty =
        QuillDeltaHelper.isDocumentEmpty(_quillController.document);

    // If both title and content are empty, do not persist a blank note
    if (title.isEmpty && isContentEmpty) {
      return true;
    }

    // Default title if user only entered body
    final finalTitle = title.isEmpty ? 'Untitled Note' : title;
    final contentJson =
        QuillDeltaHelper.documentToJson(_quillController.document);

    setState(() => _isSaving = true);

    try {
      if (_currentNote == null) {
        // Create new note
        final targetFolderId = widget.folderId;
        final created = await widget.createNote(
          folderId: targetFolderId,
          title: finalTitle,
          contentJson: contentJson,
          isPinned: _isPinned,
        );
        _currentNote = created;
        AppLogger.info('NoteEditorScreen: created note ${created.id}');
        widget.onNoteSaved?.call(created);
      } else {
        // Update existing note
        final updated = await widget.updateNote(
          id: _currentNote!.id,
          folderId: _currentNote!.folderId,
          title: finalTitle,
          contentJson: contentJson,
          isPinned: _isPinned,
        );
        _currentNote = updated;
        AppLogger.info('NoteEditorScreen: updated note ${updated.id}');
        widget.onNoteSaved?.call(updated);
      }

      _isDirty = false;
      if (mounted) {
        setState(() => _isSaving = false);
      }
      return true;
    } catch (e, st) {
      AppLogger.error('NoteEditorScreen: save failed', e, st);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  // ─── Pin toggle ───────────────────────────────────────────────────────────

  void _togglePin() {
    setState(() {
      _isPinned = !_isPinned;
      _isDirty = true;
    });
  }

  // ─── Delete note ──────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    if (_currentNote == null) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? It will be moved to trash.',
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

    if (confirmed == true && mounted) {
      try {
        await widget.deleteNote(_currentNote!.id);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, st) {
        AppLogger.error('NoteEditorScreen: delete failed', e, st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete note: ${e.toString()}')),
          );
        }
      }
    }
  }

  // ─── Navigation back interceptor ──────────────────────────────────────────

  Future<void> _onBackPressed() async {
    if (_isDirty) {
      await _saveNote();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, isDark),
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // If tapping blank area, focus the editor
                  if (!_titleFocusNode.hasFocus &&
                      !_editorFocusNode.hasFocus) {
                    _editorFocusNode.requestFocus();
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Note Title Input
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textHintLight,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(bottom: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _editorFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: 8),

                      // Rich Text Editor
                      QuillEditor.basic(
                        controller: _quillController,
                        configurations: QuillEditorConfigurations(
                          placeholder: 'Start writing your note...',
                          padding: EdgeInsets.zero,
                          expands: false,
                          autoFocus: false,
                          scrollable: false,
                        ),
                        focusNode: _editorFocusNode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Rich Text Formatting Toolbar
            SafeArea(
              top: false,
              child: NoteFormattingToolbar(controller: _quillController),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark) {
    final folderLabel = widget.folderName;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: _onBackPressed,
        tooltip: 'Back',
      ),
      title: folderLabel != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    folderLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : null,
      actions: [
        // Pin toggle button
        IconButton(
          icon: Icon(
            _isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            color: _isPinned
                ? AppColors.primaryWarmDark
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
          onPressed: _togglePin,
          tooltip: _isPinned ? 'Unpin note' : 'Pin note',
        ),

        // Save checkmark button
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: Icon(
              Icons.check_rounded,
              color: _isDirty
                  ? AppColors.primaryWarmDark
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textHintLight),
            ),
            onPressed: () async {
              final success = await _saveNote();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note saved'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            tooltip: 'Save note',
          ),

        // Context menu (for existing note)
        if (_currentNote != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(ctx).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete note',
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
