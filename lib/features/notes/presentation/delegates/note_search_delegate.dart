import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/session_manager.dart';
import '../../domain/note_entity.dart';
import '../../domain/usecases/note_crud_usecases.dart';
import '../utils/quill_delta_helper.dart';

/// Search delegate for querying notes globally with biometric protection filtering.
///
/// When [sessionManager] is locked (`isUnlocked == false`), notes belonging
/// to protected folders or their subtrees are automatically filtered out.
class NoteSearchDelegate extends SearchDelegate<NoteEntity?> {
  NoteSearchDelegate({
    required this.searchNotesUseCase,
    this.sessionManager,
    required this.onNoteSelected,
  });

  final SearchNotesUseCase searchNotesUseCase;
  final SessionManager? sessionManager;
  final void Function(NoteEntity note) onNoteSelected;

  @override
  String get searchFieldLabel => 'Search notes...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 56,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              'Type to search title or content',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final isUnlocked = sessionManager?.isUnlocked ?? false;

    return FutureBuilder<List<NoteEntity>>(
      future: searchNotesUseCase(
        query.trim(),
        includeProtected: isUnlocked,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Search error: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return Center(
            child: Text(
              'No matching notes found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          );
        }

        final dateFormat = DateFormat('MMM d, y • HH:mm');

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final note = notes[index];
            final snippet = QuillDeltaHelper.extractPlainText(note.contentJson);

            return ListTile(
              leading: Icon(
                note.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.note_alt_outlined,
                color: note.isPinned
                    ? AppColors.primaryWarm
                    : AppColors.textSecondaryLight,
              ),
              title: Text(
                note.title.isEmpty ? 'Untitled note' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (snippet.isNotEmpty)
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(note.updatedAt.toLocal()),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
              onTap: () {
                close(context, note);
                onNoteSelected(note);
              },
            );
          },
        );
      },
    );
  }
}
