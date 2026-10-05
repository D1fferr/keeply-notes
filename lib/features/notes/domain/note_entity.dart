class NoteEntity {
  final String id;
  final String? folderId;
  final String title;
  final String contentJson;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const NoteEntity({
    required this.id,
    this.folderId,
    required this.title,
    required this.contentJson,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });
}
