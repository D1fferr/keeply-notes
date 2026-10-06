import 'package:flutter/foundation.dart';
import '../../domain/note_entity.dart';

@immutable
sealed class NotesState {}

/// Initial state before notes are loaded.
final class NotesInitial extends NotesState {}

/// Data is being loaded from the database.
final class NotesLoading extends NotesState {}

/// Notes are loaded and ready to display.
final class NotesLoaded extends NotesState {
  NotesLoaded({
    required this.notes,
    this.folderId,
  });

  final List<NoteEntity> notes;
  final String? folderId;

  NotesLoaded copyWith({
    List<NoteEntity>? notes,
    String? Function()? folderId,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      folderId: folderId != null ? folderId() : this.folderId,
    );
  }
}

/// An error occurred while loading or mutating notes.
final class NotesError extends NotesState {
  NotesError(this.message);

  final String message;
}
