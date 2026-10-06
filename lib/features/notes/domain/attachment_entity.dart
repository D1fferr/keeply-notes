class AttachmentEntity {
  final String id;
  final String noteId;
  final String localPath;
  final int fileSize;

  const AttachmentEntity({
    required this.id,
    required this.noteId,
    required this.localPath,
    required this.fileSize,
  });

  AttachmentEntity copyWith({
    String? id,
    String? noteId,
    String? localPath,
    int? fileSize,
  }) {
    return AttachmentEntity(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          noteId == other.noteId &&
          localPath == other.localPath &&
          fileSize == other.fileSize;

  @override
  int get hashCode =>
      id.hashCode ^ noteId.hashCode ^ localPath.hashCode ^ fileSize.hashCode;

  @override
  String toString() =>
      'AttachmentEntity(id: $id, noteId: $noteId, localPath: $localPath, fileSize: $fileSize)';
}
