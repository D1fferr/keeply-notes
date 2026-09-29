import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/folder_entity.dart';
import '../../../notes/domain/note_entity.dart';
import 'folder_local_data_source.dart';

/// Drift-backed implementation of [FolderLocalDataSource].
///
/// All write operations update [updatedAt] to the provided [DateTime] so
/// that the Last-Write-Wins sync strategy has accurate timestamps.
class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  FolderLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  // ─── Mapping helpers ─────────────────────────────────────────────────────

  FolderEntity _toEntity(FolderData data) => FolderEntity(
        id: data.id,
        parentId: data.parentId,
        name: data.name,
        isProtected: data.isProtected,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        isDeleted: data.isDeleted,
      );

  NoteEntity _toNoteEntity(NoteData data) => NoteEntity(
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
  Stream<List<FolderEntity>> watchRootFolders() {
    return (_db.select(_db.folders)
          ..where((f) => f.parentId.isNull() & f.isDeleted.equals(false))
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<FolderEntity>> watchSubfolders(String parentId) {
    return (_db.select(_db.folders)
          ..where((f) =>
              f.parentId.equals(parentId) & f.isDeleted.equals(false))
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<FolderEntity>> watchFolderSubtree(String folderId) {
    // Drift does not natively support RECURSIVE CTEs in its query builder.
    // We use customSelect with a parameterised raw SQL statement and watch it
    // via Drift's reactive layer by listing the affected tables.
    const sql = '''
      WITH RECURSIVE SubFolders(id) AS (
        SELECT id FROM folders WHERE id = ?1 AND is_deleted = 0
        UNION ALL
        SELECT f.id FROM folders f
        INNER JOIN SubFolders sf ON f.parent_id = sf.id
        WHERE f.is_deleted = 0
      )
      SELECT folders.* FROM folders
      WHERE folders.id IN (SELECT id FROM SubFolders)
      ORDER BY folders.name ASC
    ''';

    return _db
        .customSelect(sql, variables: [Variable.withString(folderId)],
            readsFrom: {_db.folders})
        .watch()
        .map((rows) => rows.map((row) {
              final data = _db.folders.map(row.data);
              return _toEntity(data);
            }).toList());
  }

  // ─── Queries ─────────────────────────────────────────────────────────────

  @override
  Future<FolderEntity?> getFolderById(String id) async {
    final row = await (_db.select(_db.folders)
          ..where((f) => f.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<NoteEntity>> getNotesInSubtree(String folderId) async {
    const sql = '''
      WITH RECURSIVE SubFolders(id) AS (
        SELECT id FROM folders WHERE id = ?1 AND is_deleted = 0
        UNION ALL
        SELECT f.id FROM folders f
        INNER JOIN SubFolders sf ON f.parent_id = sf.id
        WHERE f.is_deleted = 0
      )
      SELECT notes.* FROM notes
      WHERE notes.folder_id IN (SELECT id FROM SubFolders)
        AND notes.is_deleted = 0
      ORDER BY notes.is_pinned DESC, notes.updated_at DESC
    ''';

    final rows = await _db.customSelect(
      sql,
      variables: [Variable.withString(folderId)],
      readsFrom: {_db.folders, _db.notes},
    ).get();

    return rows.map((row) {
      final data = _db.notes.map(row.data);
      return _toNoteEntity(data);
    }).toList();
  }

  @override
  Future<Set<String>> getSubtreeIds(String folderId) async {
    const sql = '''
      WITH RECURSIVE SubFolders(id) AS (
        SELECT id FROM folders WHERE id = ?1
        UNION ALL
        SELECT f.id FROM folders f
        INNER JOIN SubFolders sf ON f.parent_id = sf.id
      )
      SELECT id FROM SubFolders
    ''';

    final rows = await _db.customSelect(
      sql,
      variables: [Variable.withString(folderId)],
      readsFrom: {_db.folders},
    ).get();

    return rows.map((row) => row.read<String>('id')).toSet();
  }

  // ─── Mutations ───────────────────────────────────────────────────────────

  @override
  Future<FolderEntity> insertFolder({
    required String id,
    required String name,
    String? parentId,
    required bool isProtected,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final companion = FoldersCompanion(
      id: Value(id),
      name: Value(name),
      parentId: Value(parentId),
      isProtected: Value(isProtected),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
    await _db.into(_db.folders).insert(companion);
    AppLogger.debug('FolderLocalDataSource: inserted folder $id');
    return _toEntity(await (_db.select(_db.folders)
          ..where((f) => f.id.equals(id)))
        .getSingle());
  }

  @override
  Future<FolderEntity> updateFolderName(
      String id, String newName, DateTime updatedAt) async {
    await (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(
        name: Value(newName),
        updatedAt: Value(updatedAt),
      ),
    );
    AppLogger.debug('FolderLocalDataSource: renamed folder $id → "$newName"');
    return _toEntity(await (_db.select(_db.folders)
          ..where((f) => f.id.equals(id)))
        .getSingle());
  }

  @override
  Future<FolderEntity> updateFolderParent(
      String id, String? newParentId, DateTime updatedAt) async {
    await (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(
        parentId: Value(newParentId),
        updatedAt: Value(updatedAt),
      ),
    );
    AppLogger.debug(
        'FolderLocalDataSource: moved folder $id → parent $newParentId');
    return _toEntity(await (_db.select(_db.folders)
          ..where((f) => f.id.equals(id)))
        .getSingle());
  }

  @override
  Future<FolderEntity> updateFolderProtection(
      String id, bool isProtected, DateTime updatedAt) async {
    await (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(
      FoldersCompanion(
        isProtected: Value(isProtected),
        updatedAt: Value(updatedAt),
      ),
    );
    AppLogger.debug(
        'FolderLocalDataSource: set isProtected=$isProtected on folder $id');
    return _toEntity(await (_db.select(_db.folders)
          ..where((f) => f.id.equals(id)))
        .getSingle());
  }

  @override
  Future<void> softDeleteFolderSubtree(String folderId) async {
    // Collect all descendant IDs via the recursive CTE, then bulk-update them.
    final ids = await getSubtreeIds(folderId);
    if (ids.isEmpty) return;

    final now = DateTime.now().toUtc();

    // Drift does not support WHERE IN with a list out of the box for updates,
    // so we iterate; the list is typically small (< 100 folders).
    for (final id in ids) {
      await (_db.update(_db.folders)..where((f) => f.id.equals(id))).write(
        FoldersCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
    AppLogger.debug(
        'FolderLocalDataSource: soft-deleted ${ids.length} folders in subtree of $folderId');
  }
}
