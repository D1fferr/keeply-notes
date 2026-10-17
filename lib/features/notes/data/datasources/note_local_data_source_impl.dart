import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/note_entity.dart';
import 'note_local_data_source.dart';

/// Drift-backed implementation of [NoteLocalDataSource].
///
/// All write operations update [updatedAt] to the provided [DateTime] so
/// that the Last-Write-Wins sync strategy has accurate timestamps.
class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  NoteLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  // ─── Mapping helpers ─────────────────────────────────────────────────────

  NoteEntity _toEntity(NoteData data) => NoteEntity(
        id: data.id,
        folderId: data.folderId,
        title: data.title,
        contentJson: data.contentJson,
        isPinned: data.isPinned,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        isDeleted: data.isDeleted,
      );

  // ─── Streams ─────────────────────────────────────────────────────────────

  @override
  Stream<List<NoteEntity>> watchNotesInFolder(String? folderId) {
    final query = _db.select(_db.notes)
      ..where((n) {
        final folderFilter = folderId == null
            ? n.folderId.isNull()
            : n.folderId.equals(folderId);
        return folderFilter & n.isDeleted.equals(false);
      })
      ..orderBy([
        (n) => OrderingTerm.desc(n.isPinned),
        (n) => OrderingTerm.desc(n.updatedAt),
      ]);

    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<NoteEntity>> watchAllNotes({bool includeProtected = true}) {
    if (includeProtected) {
      final query = _db.select(_db.notes)
        ..where((n) => n.isDeleted.equals(false))
        ..orderBy([
          (n) => OrderingTerm.desc(n.isPinned),
          (n) => OrderingTerm.desc(n.updatedAt),
        ]);

      return query.watch().map((rows) => rows.map(_toEntity).toList());
    }

    // Exclude notes that belong to protected folders or their subtrees.
    const sql = '''
      WITH RECURSIVE ProtectedSubtree(id) AS (
        SELECT id FROM folders WHERE is_protected = 1 AND is_deleted = 0
        UNION ALL
        SELECT f.id FROM folders f
        INNER JOIN ProtectedSubtree ps ON f.parent_id = ps.id
        WHERE f.is_deleted = 0
      )
      SELECT notes.* FROM notes
      WHERE notes.is_deleted = 0
        AND (notes.folder_id IS NULL
             OR notes.folder_id NOT IN (SELECT id FROM ProtectedSubtree))
      ORDER BY notes.is_pinned DESC, notes.updated_at DESC
    ''';

    return _db
        .customSelect(sql, readsFrom: {_db.notes, _db.folders})
        .watch()
        .map((rows) => rows.map((row) {
              final data = _db.notes.map(row.data);
              return _toEntity(data);
            }).toList());
  }

  @override
  Future<List<NoteEntity>> searchNotes(
    String query, {
    bool includeProtected = true,
  }) async {
    final pattern = '%${query.toLowerCase()}%';

    if (includeProtected) {
      const sql = '''
        SELECT * FROM notes
        WHERE is_deleted = 0
          AND (LOWER(title) LIKE ?1 OR LOWER(content_json) LIKE ?1)
        ORDER BY is_pinned DESC, updated_at DESC
      ''';

      final rows = await _db.customSelect(
        sql,
        variables: [Variable.withString(pattern)],
        readsFrom: {_db.notes},
      ).get();

      return rows.map((row) {
        final data = _db.notes.map(row.data);
        return _toEntity(data);
      }).toList();
    }

    const sql = '''
      WITH RECURSIVE ProtectedSubtree(id) AS (
        SELECT id FROM folders WHERE is_protected = 1 AND is_deleted = 0
        UNION ALL
        SELECT f.id FROM folders f
        INNER JOIN ProtectedSubtree ps ON f.parent_id = ps.id
        WHERE f.is_deleted = 0
      )
      SELECT notes.* FROM notes
      WHERE notes.is_deleted = 0
        AND (LOWER(notes.title) LIKE ?1 OR LOWER(notes.content_json) LIKE ?1)
        AND (notes.folder_id IS NULL
             OR notes.folder_id NOT IN (SELECT id FROM ProtectedSubtree))
      ORDER BY notes.is_pinned DESC, notes.updated_at DESC
    ''';

    final rows = await _db.customSelect(
      sql,
      variables: [Variable.withString(pattern)],
      readsFrom: {_db.notes, _db.folders},
    ).get();

    return rows.map((row) {
      final data = _db.notes.map(row.data);
      return _toEntity(data);
    }).toList();
  }

  // ─── Queries ─────────────────────────────────────────────────────────────

  @override
  Future<NoteEntity?> getNoteById(String id) async {
    final row = await (_db.select(_db.notes)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  // ─── Mutations ───────────────────────────────────────────────────────────

  @override
  Future<NoteEntity> insertNote({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    required bool isPinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final companion = NotesCompanion(
      id: Value(id),
      folderId: Value(folderId),
      title: Value(title),
      contentJson: Value(contentJson),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: const Value(false),
    );

    await _db.into(_db.notes).insert(companion);
    AppLogger.debug('NoteLocalDataSource: inserted note $id');
    return _toEntity(await (_db.select(_db.notes)
          ..where((n) => n.id.equals(id)))
        .getSingle());
  }

  @override
  Future<NoteEntity> updateNote({
    required String id,
    String? folderId,
    required String title,
    required String contentJson,
    bool? isPinned,
    required DateTime updatedAt,
  }) async {
    final companion = NotesCompanion(
      folderId: Value(folderId),
      title: Value(title),
      contentJson: Value(contentJson),
      isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
      updatedAt: Value(updatedAt),
    );

    await (_db.update(_db.notes)..where((n) => n.id.equals(id)))
        .write(companion);
    AppLogger.debug('NoteLocalDataSource: updated note $id');
    return _toEntity(await (_db.select(_db.notes)
          ..where((n) => n.id.equals(id)))
        .getSingle());
  }

  @override
  Future<NoteEntity> togglePin(String id, DateTime updatedAt) async {
    final existing = await (_db.select(_db.notes)
          ..where((n) => n.id.equals(id)))
        .getSingle();

    final newPinned = !existing.isPinned;
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        isPinned: Value(newPinned),
        updatedAt: Value(updatedAt),
      ),
    );

    AppLogger.debug(
        'NoteLocalDataSource: toggled isPinned=$newPinned on note $id');
    return _toEntity(await (_db.select(_db.notes)
          ..where((n) => n.id.equals(id)))
        .getSingle());
  }

  @override
  Future<NoteEntity> updateNoteFolder(
    String id,
    String? newFolderId,
    DateTime updatedAt,
  ) async {
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        folderId: Value(newFolderId),
        updatedAt: Value(updatedAt),
      ),
    );

    AppLogger.debug('NoteLocalDataSource: moved note $id to folder $newFolderId');
    return _toEntity(await (_db.select(_db.notes)
          ..where((n) => n.id.equals(id)))
        .getSingle());
  }

  @override
  Future<void> softDeleteNote(String id, DateTime updatedAt) async {
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
    AppLogger.debug('NoteLocalDataSource: soft-deleted note $id');
  }
}
