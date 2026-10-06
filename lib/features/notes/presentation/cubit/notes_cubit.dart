import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/note_entity.dart';
import '../../domain/usecases/note_crud_usecases.dart';
import 'notes_state.dart';

/// Manages the real-time list of notes for the current folder (or root level).
///
/// Subscribes to Drift stream via [WatchNotesInFolderUseCase] so the UI
/// automatically updates when notes are created, modified, or deleted.
class NotesCubit extends ChangeNotifier {
  NotesCubit({
    required WatchNotesInFolderUseCase watchNotesInFolder,
    required TogglePinNoteUseCase togglePinNote,
    required DeleteNoteUseCase deleteNote,
    required MoveNoteUseCase moveNote,
    String? initialFolderId,
  })  : _watchNotesInFolder = watchNotesInFolder,
        _togglePinNote = togglePinNote,
        _deleteNote = deleteNote,
        _moveNote = moveNote {
    loadNotesForFolder(initialFolderId);
  }

  final WatchNotesInFolderUseCase _watchNotesInFolder;
  final TogglePinNoteUseCase _togglePinNote;
  final DeleteNoteUseCase _deleteNote;
  final MoveNoteUseCase _moveNote;

  NotesState _state = NotesInitial();
  NotesState get state => _state;

  StreamSubscription<List<NoteEntity>>? _notesSub;
  String? _currentFolderId;
  String? get currentFolderId => _currentFolderId;

  // ─── Subscriptions ────────────────────────────────────────────────────────

  /// Switches the reactive stream to listen for notes belonging to [folderId].
  ///
  /// Pass `null` for root-level notes.
  void loadNotesForFolder(String? folderId) {
    _currentFolderId = folderId;
    _notesSub?.cancel();

    _setState(NotesLoading());

    _notesSub = _watchNotesInFolder(folderId).listen(
      (notes) {
        _setState(NotesLoaded(
          notes: notes,
          folderId: folderId,
        ));
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error('NotesCubit stream error', e, st);
        _setState(NotesError(e.toString()));
      },
    );
  }

  // ─── Mutations ────────────────────────────────────────────────────────────

  /// Toggles the pin status of [noteId].
  Future<void> togglePin(String noteId) async {
    try {
      await _togglePinNote(noteId);
    } catch (e, st) {
      AppLogger.error('NotesCubit.togglePin failed', e, st);
      _setState(NotesError('Failed to toggle pin: ${e.toString()}'));
    }
  }

  /// Moves [noteId] to [newFolderId] (or root if null).
  Future<void> moveNote(String noteId, String? newFolderId) async {
    try {
      await _moveNote(noteId, newFolderId);
    } catch (e, st) {
      AppLogger.error('NotesCubit.moveNote failed', e, st);
      _setState(NotesError('Failed to move note: ${e.toString()}'));
    }
  }

  /// Soft-deletes [noteId].
  Future<void> deleteNote(String noteId) async {
    try {
      await _deleteNote(noteId);
    } catch (e, st) {
      AppLogger.error('NotesCubit.deleteNote failed', e, st);
      _setState(NotesError('Failed to delete note: ${e.toString()}'));
    }
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  void _setState(NotesState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    super.dispose();
  }
}
