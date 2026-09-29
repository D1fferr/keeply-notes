// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class FolderData extends DataClass implements Insertable<FolderData> {
  final String id;
  final String? parentId;
  final String name;
  final bool isProtected;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const FolderData({
    required this.id,
    this.parentId,
    required this.name,
    required this.isProtected,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  @override
  Map<String, Expression> toColumns(bool nullToEmpty) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToEmpty || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['is_protected'] = Variable<bool>(isProtected);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToEmpty) {
    return FoldersCompanion(
      id: Value(id),
      parentId: parentId == null && !nullToEmpty ? const Value.absent() : Value(parentId),
      name: Value(name),
      isProtected: Value(isProtected),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory FolderData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderData(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      isProtected: serializer.fromJson<bool>(json['isProtected']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'isProtected': serializer.toJson<bool>(isProtected),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  FolderData copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    bool? isProtected,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      FolderData(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        isProtected: isProtected ?? this.isProtected,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}

class FoldersCompanion extends UpdateCompanion<FolderData> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<bool> isProtected;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, FolderData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true, type: DriftSqlType.string,
      defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES folders (id)'));
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isProtected = GeneratedColumn<bool>(
      'is_protected', aliasedName, false,
      type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_protected" IN (0, 1))'), defaultValue: const Constant(false));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'), defaultValue: const Constant(false));

  @override
  List<GeneratedColumn> get $columns => [id, parentId, name, isProtected, createdAt, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isProtected: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_protected'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }
  @override
  $FoldersTable createAlias(String alias) => $FoldersTable(attachedDatabase, alias);
}

class NoteData extends DataClass implements Insertable<NoteData> {
  final String id;
  final String? folderId;
  final String title;
  final String contentJson;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const NoteData({
    required this.id,
    this.folderId,
    required this.title,
    required this.contentJson,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  @override
  Map<String, Expression> toColumns(bool nullToEmpty) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToEmpty || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['title'] = Variable<String>(title);
    map['content_json'] = Variable<String>(contentJson);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  NotesCompanion toCompanion(bool nullToEmpty) {
    return NotesCompanion(
      id: Value(id),
      folderId: folderId == null && !nullToEmpty ? const Value.absent() : Value(folderId),
      title: Value(title),
      contentJson: Value(contentJson),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory NoteData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteData(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      title: serializer.fromJson<String>(json['title']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String?>(folderId),
      'title': serializer.toJson<String>(title),
      'contentJson': serializer.toJson<String>(contentJson),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }
}

class NotesCompanion extends UpdateCompanion<NoteData> {
  final Value<String> id;
  final Value<String?> folderId;
  final Value<String> title;
  final Value<String> contentJson;
  final Value<bool> isPinned;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.title = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true, type: DriftSqlType.string,
      defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES folders (id)'));
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'), defaultValue: const Constant(false));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'), defaultValue: const Constant(false));

  @override
  List<GeneratedColumn> get $columns => [id, folderId, title, contentJson, isPinned, createdAt, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      folderId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      contentJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      isPinned: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }
  @override
  $NotesTable createAlias(String alias) => $NotesTable(attachedDatabase, alias);
}

class ReminderData extends DataClass implements Insertable<ReminderData> {
  final String id;
  final String noteId;
  final DateTime startDateTime;
  final String repeatType;
  final int? customDaysInterval;
  final bool isEnabled;
  const ReminderData({
    required this.id,
    required this.noteId,
    required this.startDateTime,
    required this.repeatType,
    this.customDaysInterval,
    required this.isEnabled,
  });

  @override
  Map<String, Expression> toColumns(bool nullToEmpty) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['start_date_time'] = Variable<DateTime>(startDateTime);
    map['repeat_type'] = Variable<String>(repeatType);
    if (!nullToEmpty || customDaysInterval != null) {
      map['custom_days_interval'] = Variable<int>(customDaysInterval);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }
}

class RemindersCompanion extends UpdateCompanion<ReminderData> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<DateTime> startDateTime;
  final Value<String> repeatType;
  final Value<int?> customDaysInterval;
  final Value<bool> isEnabled;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.startDateTime = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.customDaysInterval = const Value.absent(),
    this.isEnabled = const Value.absent(),
  });
}

class $RemindersTable extends Reminders with TableInfo<$RemindersTable, ReminderData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE REFERENCES notes (id)'));
  late final GeneratedColumn<DateTime> startDateTime = GeneratedColumn<DateTime>(
      'start_date_time', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<String> repeatType = GeneratedColumn<String>(
      'repeat_type', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> customDaysInterval = GeneratedColumn<int>(
      'custom_days_interval', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'), defaultValue: const Constant(true));

  @override
  List<GeneratedColumn> get $columns => [id, noteId, startDateTime, repeatType, customDaysInterval, isEnabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      startDateTime: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}start_date_time'])!,
      repeatType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}repeat_type'])!,
      customDaysInterval: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}custom_days_interval']),
      isEnabled: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
    );
  }
  @override
  $RemindersTable createAlias(String alias) => $RemindersTable(attachedDatabase, alias);
}

class SubReminderData extends DataClass implements Insertable<SubReminderData> {
  final String id;
  final String reminderId;
  final String type;
  final int? offsetMinutes;
  final String? exactTime;
  const SubReminderData({
    required this.id,
    required this.reminderId,
    required this.type,
    this.offsetMinutes,
    this.exactTime,
  });

  @override
  Map<String, Expression> toColumns(bool nullToEmpty) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reminder_id'] = Variable<String>(reminderId);
    map['type'] = Variable<String>(type);
    if (!nullToEmpty || offsetMinutes != null) {
      map['offset_minutes'] = Variable<int>(offsetMinutes);
    }
    if (!nullToEmpty || exactTime != null) {
      map['exact_time'] = Variable<String>(exactTime);
    }
    return map;
  }
}

class SubRemindersCompanion extends UpdateCompanion<SubReminderData> {
  final Value<String> id;
  final Value<String> reminderId;
  final Value<String> type;
  final Value<int?> offsetMinutes;
  final Value<String?> exactTime;
  const SubRemindersCompanion({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.type = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.exactTime = const Value.absent(),
  });
}

class $SubRemindersTable extends SubReminders with TableInfo<$SubRemindersTable, SubReminderData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubRemindersTable(this.attachedDatabase, [this._alias]);
  
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
      'reminder_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES reminders (id) ON DELETE CASCADE'));
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
      'offset_minutes', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> exactTime = GeneratedColumn<String>(
      'exact_time', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);

  @override
  List<GeneratedColumn> get $columns => [id, reminderId, type, offsetMinutes, exactTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sub_reminders';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubReminderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubReminderData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      reminderId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reminder_id'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      offsetMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}offset_minutes']),
      exactTime: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exact_time']),
    );
  }
  @override
  $SubRemindersTable createAlias(String alias) => $SubRemindersTable(attachedDatabase, alias);
}

class AttachmentData extends DataClass implements Insertable<AttachmentData> {
  final String id;
  final String noteId;
  final String localPath;
  final int fileSize;
  const AttachmentData({
    required this.id,
    required this.noteId,
    required this.localPath,
    required this.fileSize,
  });

  @override
  Map<String, Expression> toColumns(bool nullToEmpty) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['local_path'] = Variable<String>(localPath);
    map['file_size'] = Variable<int>(fileSize);
    return map;
  }
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentData> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> localPath;
  final Value<int> fileSize;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
  });
}

class $AttachmentsTable extends Attachments with TableInfo<$AttachmentsTable, AttachmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES notes (id)'));
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);

  @override
  List<GeneratedColumn> get $columns => [id, noteId, localPath, fileSize];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      localPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      fileSize: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
    );
  }
  @override
  $AttachmentsTable createAlias(String alias) => $AttachmentsTable(attachedDatabase, alias);
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $SubRemindersTable subReminders = $SubRemindersTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [folders, notes, reminders, subReminders, attachments];
}
