import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/session_manager.dart';
import '../../../reminders/domain/usecases/reminder_usecases.dart';
import '../../domain/note_entity.dart';
import '../../domain/usecases/note_crud_usecases.dart';
import '../utils/quill_delta_helper.dart';
import 'note_search_filter.dart';

/// Instant search engine delegate across note titles and content,
/// respecting biometric folder protection and providing quick filter chips.
class NoteSearchDelegate extends SearchDelegate<NoteEntity?> {
  NoteSearchDelegate({
    required this.searchNotesUseCase,
    this.sessionManager,
    this.getAllActiveRemindersUseCase,
    required this.onNoteSelected,
  });

  final SearchNotesUseCase searchNotesUseCase;
  final SessionManager? sessionManager;
  final GetAllActiveRemindersUseCase? getAllActiveRemindersUseCase;
  final void Function(NoteEntity note) onNoteSelected;

  final ValueNotifier<NoteSearchFilter> _filterNotifier =
      ValueNotifier<NoteSearchFilter>(NoteSearchFilter.all);

  @override
  String get searchFieldLabel => 'Search notes...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        fillColor: Colors.transparent,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          tooltip: 'Clear query',
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
      tooltip: 'Back',
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchContent(context);
  }

  Widget _buildFilterChips(BuildContext context) {
    return ValueListenableBuilder<NoteSearchFilter>(
      valueListenable: _filterNotifier,
      builder: (context, currentFilter, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: currentFilter == NoteSearchFilter.all,
                onSelected: (_) => _filterNotifier.value = NoteSearchFilter.all,
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.push_pin_rounded, size: 16),
                label: const Text('Pinned'),
                selected: currentFilter == NoteSearchFilter.pinned,
                onSelected: (selected) {
                  _filterNotifier.value = selected
                      ? NoteSearchFilter.pinned
                      : NoteSearchFilter.all;
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.alarm_rounded, size: 16),
                label: const Text('Has Reminders'),
                selected: currentFilter == NoteSearchFilter.hasReminders,
                onSelected: (selected) {
                  _filterNotifier.value = selected
                      ? NoteSearchFilter.hasReminders
                      : NoteSearchFilter.all;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    final trimmedQuery = query.trim();
    final isUnlocked = sessionManager?.isUnlocked ?? false;

    return Column(
      children: [
        _buildFilterChips(context),
        const Divider(height: 1),
        Expanded(
          child: ValueListenableBuilder<NoteSearchFilter>(
            valueListenable: _filterNotifier,
            builder: (context, filter, _) {
              if (trimmedQuery.isEmpty && filter == NoteSearchFilter.all) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 56,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Type to search title or content',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return FutureBuilder<_SearchResultsData>(
                future: _fetchFilteredResults(trimmedQuery, isUnlocked, filter),
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

                  final data = snapshot.data;
                  final notes = data?.notes ?? [];
                  final reminderNoteIds = data?.reminderNoteIds ?? <String>{};

                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        'No matching notes found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                      final snippet =
                          QuillDeltaHelper.extractPlainText(note.contentJson);
                      final hasReminder = reminderNoteIds.contains(note.id);

                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              note.isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.note_alt_outlined,
                              color: note.isPinned
                                  ? AppColors.primaryWarmDark
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            if (hasReminder)
                              const Positioned(
                                right: -4,
                                bottom: -4,
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  size: 14,
                                  color: AppColors.reminderActive,
                                ),
                              ),
                          ],
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  dateFormat.format(note.updatedAt.toLocal()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                if (hasReminder) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.alarm_rounded,
                                    size: 12,
                                    color: AppColors.reminderActive,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Reminder active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.reminderActive,
                                    ),
                                  ),
                                ],
                              ],
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
            },
          ),
        ),
      ],
    );
  }

  Future<_SearchResultsData> _fetchFilteredResults(
    String trimmedQuery,
    bool isUnlocked,
    NoteSearchFilter filter,
  ) async {
    // 1. Fetch matching notes
    final notes = await searchNotesUseCase(
      trimmedQuery,
      includeProtected: isUnlocked,
    );

    // 2. Fetch reminder IDs if available
    final reminderNoteIds = <String>{};
    if (getAllActiveRemindersUseCase != null) {
      final activeReminders = await getAllActiveRemindersUseCase!();
      for (final r in activeReminders) {
        reminderNoteIds.add(r.noteId);
      }
    }

    // 3. Apply client-side filter chips
    final filteredNotes = notes.where((note) {
      switch (filter) {
        case NoteSearchFilter.all:
          return true;
        case NoteSearchFilter.pinned:
          return note.isPinned;
        case NoteSearchFilter.hasReminders:
          return reminderNoteIds.contains(note.id);
      }
    }).toList();

    return _SearchResultsData(
      notes: filteredNotes,
      reminderNoteIds: reminderNoteIds,
    );
  }
}

class _SearchResultsData {
  const _SearchResultsData({
    required this.notes,
    required this.reminderNoteIds,
  });

  final List<NoteEntity> notes;
  final Set<String> reminderNoteIds;
}
