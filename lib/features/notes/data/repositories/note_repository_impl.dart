import 'package:uuid/uuid.dart';
import '../../domain/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_data_source.dart';

/// Implementation of [NoteRepository] that delegates to [NoteLocalDataSource]
/// and generates UUIDs and UTC timestamps for note mutations.
class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._dataSource) : _uuid = const Uuid();

  final NoteLocalDataSource _dataSource;
  final Uuid _uuid;

  // ─── Read ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<NoteEntity>> watchNotesInFolder(String? folderId) =>
      _dataSource.watchNotesInFolder(folderId);

  @override
  Stream<List<NoteEntity>> watchAllNotes() => _dataSource.watchAllNotes();

  @override
  Future<NoteEntity?> getNoteById(String id) => _dataSource.getNoteById(id);

  // ─── Write ────────────────────────────────────────────────────────────────

  @override
  Future<NoteEntity> createNote({
    String? folderId,
    required String title,
    required String contentJson,
    bool isPinned = false,
  }) {
    final now = DateTime.now().toUtc();
    return _dataSource.insertNote(
      id: _uuid.v4(),
      folderId: folderId,
      title: title.trim(),
      contentJson: contentJson,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<NoteEntity> updateNote({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    bool? isPinned,
  }) {
    final now = DateTime.now().toUtc();
    return _dataSource.updateNote(
      id: id,
      folderId: folderId,
      title: title.trim(),
      contentJson: contentJson,
      isPinned: isPinned,
      updatedAt: now,
    );
  }

  @override
  Future<NoteEntity> togglePin(String id) {
    final now = DateTime.now().toUtc();
    return _dataSource.togglePin(id, now);
  }

  @override
  Future<NoteEntity> moveNote(String id, String? newFolderId) {
    final now = DateTime.now().toUtc();
    return _dataSource.updateNoteFolder(id, newFolderId, now);
  }

  @override
  Future<void> deleteNote(String id) {
    final now = DateTime.now().toUtc();
    return _dataSource.softDeleteNote(id, now);
  }
}
