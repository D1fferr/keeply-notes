class FolderEntity {
  final String id;
  final String? parentId;
  final String name;
  final bool isProtected;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const FolderEntity({
    required this.id,
    this.parentId,
    required this.name,
    this.isProtected = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });
}
