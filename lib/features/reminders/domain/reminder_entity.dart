enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  customDays;

  static RepeatType fromString(String value) {
    return switch (value) {
      'daily' => RepeatType.daily,
      'weekly' => RepeatType.weekly,
      'monthly' => RepeatType.monthly,
      'yearly' => RepeatType.yearly,
      'customDays' || 'custom_days' => RepeatType.customDays,
      _ => RepeatType.none,
    };
  }

  String toDbString() {
    return switch (this) {
      RepeatType.none => 'none',
      RepeatType.daily => 'daily',
      RepeatType.weekly => 'weekly',
      RepeatType.monthly => 'monthly',
      RepeatType.yearly => 'yearly',
      RepeatType.customDays => 'custom_days',
    };
  }
}

enum SubReminderType {
  offsetMinutes,
  exactTime;

  static SubReminderType fromString(String value) {
    return switch (value) {
      'exactTime' || 'exact_time' => SubReminderType.exactTime,
      _ => SubReminderType.offsetMinutes,
    };
  }

  String toDbString() {
    return switch (this) {
      SubReminderType.offsetMinutes => 'offset_minutes',
      SubReminderType.exactTime => 'exact_time',
    };
  }
}

class ReminderEntity {
  final String id;
  final String noteId;
  final DateTime startDateTime;
  final RepeatType repeatType;
  final int? customDaysInterval;
  final bool isEnabled;

  const ReminderEntity({
    required this.id,
    required this.noteId,
    required this.startDateTime,
    this.repeatType = RepeatType.none,
    this.customDaysInterval,
    this.isEnabled = true,
  });

  ReminderEntity copyWith({
    String? id,
    String? noteId,
    DateTime? startDateTime,
    RepeatType? repeatType,
    int? Function()? customDaysInterval,
    bool? isEnabled,
  }) {
    return ReminderEntity(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      startDateTime: startDateTime ?? this.startDateTime,
      repeatType: repeatType ?? this.repeatType,
      customDaysInterval: customDaysInterval != null
          ? customDaysInterval()
          : this.customDaysInterval,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          noteId == other.noteId &&
          startDateTime == other.startDateTime &&
          repeatType == other.repeatType &&
          customDaysInterval == other.customDaysInterval &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      id.hashCode ^
      noteId.hashCode ^
      startDateTime.hashCode ^
      repeatType.hashCode ^
      customDaysInterval.hashCode ^
      isEnabled.hashCode;

  @override
  String toString() =>
      'ReminderEntity(id: $id, noteId: $noteId, startDateTime: $startDateTime, repeatType: $repeatType, isEnabled: $isEnabled)';
}

class SubReminderEntity {
  final String id;
  final String reminderId;
  final SubReminderType type;
  final int? offsetMinutes;
  final String? exactTime;

  const SubReminderEntity({
    required this.id,
    required this.reminderId,
    required this.type,
    this.offsetMinutes,
    this.exactTime,
  });

  SubReminderEntity copyWith({
    String? id,
    String? reminderId,
    SubReminderType? type,
    int? Function()? offsetMinutes,
    String? Function()? exactTime,
  }) {
    return SubReminderEntity(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      type: type ?? this.type,
      offsetMinutes:
          offsetMinutes != null ? offsetMinutes() : this.offsetMinutes,
      exactTime: exactTime != null ? exactTime() : this.exactTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubReminderEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reminderId == other.reminderId &&
          type == other.type &&
          offsetMinutes == other.offsetMinutes &&
          exactTime == other.exactTime;

  @override
  int get hashCode =>
      id.hashCode ^
      reminderId.hashCode ^
      type.hashCode ^
      offsetMinutes.hashCode ^
      exactTime.hashCode;

  @override
  String toString() =>
      'SubReminderEntity(id: $id, reminderId: $reminderId, type: $type, offsetMinutes: $offsetMinutes, exactTime: $exactTime)';
}
