enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  customDays,
}

enum SubReminderType {
  offsetMinutes,
  exactTime,
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
}
