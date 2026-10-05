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

  NoteEntity copyWith({
    String? id,
    String? Function()? folderId,
    String? title,
    String? contentJson,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      folderId: folderId != null ? folderId() : this.folderId,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          folderId == other.folderId &&
          title == other.title &&
          contentJson == other.contentJson &&
          isPinned == other.isPinned &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode =>
      id.hashCode ^
      folderId.hashCode ^
      title.hashCode ^
      contentJson.hashCode ^
      isPinned.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      isDeleted.hashCode;

  @override
  String toString() =>
      'NoteEntity(id: $id, folderId: $folderId, title: $title, isPinned: $isPinned, updatedAt: $updatedAt)';
}
