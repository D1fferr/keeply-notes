import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/features/folders/domain/folder_entity.dart';
import 'package:keeply_notes/features/notes/domain/note_entity.dart';

/// In-memory graph model that emulates the exact SQLite CTE recursive queries
/// used by [FolderLocalDataSourceImpl.getNotesInSubtree] and [getSubtreeIds].
class CteSubtreeResolver {
  CteSubtreeResolver({
    required this.folders,
    required this.notes,
  });

  final List<FolderEntity> folders;
  final List<NoteEntity> notes;

  /// Emulates:
  /// WITH RECURSIVE SubFolders(id) AS (
  ///   SELECT id FROM folders WHERE id = ?1
  ///   UNION ALL
  ///   SELECT f.id FROM folders f INNER JOIN SubFolders sf ON f.parent_id = sf.id
  /// )
  Set<String> getSubtreeIds(String rootFolderId) {
    final result = <String>{rootFolderId};
    final queue = <String>[rootFolderId];

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      for (final f in folders) {
        if (!f.isDeleted && f.parentId == currentId && !result.contains(f.id)) {
          result.add(f.id);
          queue.add(f.id);
        }
      }
    }
    return result;
  }

  /// Emulates CTE to fetch all non-deleted notes inside the folder subtree.
  List<NoteEntity> getNotesInSubtree(String rootFolderId) {
    final subtreeIds = getSubtreeIds(rootFolderId);
    final subtreeNotes = notes.where((n) {
      return !n.isDeleted && n.folderId != null && subtreeIds.contains(n.folderId);
    }).toList();

    // ORDER BY is_pinned DESC, updated_at DESC
    subtreeNotes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return subtreeNotes;
  }
}

void main() {
  final now = DateTime.now();

  // Folder hierarchy:
  // Root -> Work -> ProjectA -> Tasks
  // Root -> Personal
  // Trash (is_deleted = true)
  final folderWork = FolderEntity(
    id: 'f-work',
    parentId: null,
    name: 'Work',
    isProtected: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final folderProjectA = FolderEntity(
    id: 'f-project-a',
    parentId: 'f-work',
    name: 'Project A',
    isProtected: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final folderTasks = FolderEntity(
    id: 'f-tasks',
    parentId: 'f-project-a',
    name: 'Tasks',
    isProtected: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final folderPersonal = FolderEntity(
    id: 'f-personal',
    parentId: null,
    name: 'Personal',
    isProtected: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final folderDeleted = FolderEntity(
    id: 'f-deleted',
    parentId: 'f-work',
    name: 'Old Arch',
    isProtected: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: true,
  );

  final folders = [
    folderWork,
    folderProjectA,
    folderTasks,
    folderPersonal,
    folderDeleted,
  ];

  final noteInWork = NoteEntity(
    id: 'n-work',
    folderId: 'f-work',
    title: 'Work Overview',
    contentJson: '[]',
    isPinned: false,
    createdAt: now,
    updatedAt: now.subtract(const Duration(minutes: 10)),
    isDeleted: false,
  );

  final noteInProjectA = NoteEntity(
    id: 'n-proj-a',
    folderId: 'f-project-a',
    title: 'Architecture Spec',
    contentJson: '[]',
    isPinned: true, // Pinned note
    createdAt: now,
    updatedAt: now.subtract(const Duration(minutes: 5)),
    isDeleted: false,
  );

  final noteInTasks = NoteEntity(
    id: 'n-tasks',
    folderId: 'f-tasks',
    title: 'Task Checklist',
    contentJson: '[]',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final noteInPersonal = NoteEntity(
    id: 'n-personal',
    folderId: 'f-personal',
    title: 'Groceries',
    contentJson: '[]',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );

  final noteDeleted = NoteEntity(
    id: 'n-del',
    folderId: 'f-tasks',
    title: 'Discarded Idea',
    contentJson: '[]',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    isDeleted: true,
  );

  final notes = [
    noteInWork,
    noteInProjectA,
    noteInTasks,
    noteInPersonal,
    noteDeleted,
  ];

  group('Recursive CTE Subtree Queries', () {
    late CteSubtreeResolver resolver;

    setUp(() {
      resolver = CteSubtreeResolver(folders: folders, notes: notes);
    });

    test('recursively resolves all subtree folder IDs at any depth', () {
      final subtreeWork = resolver.getSubtreeIds('f-work');
      expect(subtreeWork, containsAll(['f-work', 'f-project-a', 'f-tasks']));
      expect(subtreeWork, isNot(contains('f-personal')));
      expect(subtreeWork, isNot(contains('f-deleted')));

      final subtreeProjA = resolver.getSubtreeIds('f-project-a');
      expect(subtreeProjA, containsAll(['f-project-a', 'f-tasks']));
      expect(subtreeProjA, isNot(contains('f-work')));
    });

    test('returns all notes across multi-level subfolders within target subtree', () {
      final workNotes = resolver.getNotesInSubtree('f-work');
      expect(workNotes.length, 3);
      expect(workNotes.map((n) => n.id), containsAll(['n-work', 'n-proj-a', 'n-tasks']));
      expect(workNotes.map((n) => n.id), isNot(contains('n-personal')));
      expect(workNotes.map((n) => n.id), isNot(contains('n-del')));
    });

    test('preserves sorting order: pinned notes first, then updated_at desc', () {
      final workNotes = resolver.getNotesInSubtree('f-work');
      // n-proj-a is pinned, so it should be first
      expect(workNotes.first.id, 'n-proj-a');
      expect(workNotes.first.isPinned, isTrue);

      // Remaining unpinned sorted by updatedAt descending: n-tasks (now) > n-work (-10m)
      expect(workNotes[1].id, 'n-tasks');
      expect(workNotes[2].id, 'n-work');
    });

    test('leaf folder subtree returns only its own notes', () {
      final taskNotes = resolver.getNotesInSubtree('f-tasks');
      expect(taskNotes.length, 1);
      expect(taskNotes.first.id, 'n-tasks');
    });
  });
}
