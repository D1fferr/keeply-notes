import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/reminder_entity.dart';
import '../../domain/services/sub_reminder_calculator.dart';

/// Modal bottom sheet allowing users to configure or remove a note's primary reminder
/// and up to 10 secondary sub-reminders (offset minutes & exact time).
///
/// Supports:
/// - Quick presets (e.g. In 1 hour, Tomorrow morning)
/// - Custom Date & Time picker
/// - Recurrence options (`none`, `daily`, `weekly`, `monthly`, `yearly`, `customDays`)
/// - Custom day interval input
/// - Secondary sub-reminders list (up to 10) with offset and exact time options
/// - Active/inactive toggle
/// - Removal of existing reminder and all cascading sub-reminders
class ReminderPickerSheet extends StatefulWidget {
  const ReminderPickerSheet({
    super.key,
    this.existingReminder,
    this.existingSubReminders,
    required this.onSave,
    this.onDelete,
  });

  final ReminderEntity? existingReminder;
  final List<SubReminderEntity>? existingSubReminders;
  final void Function({
    required DateTime startDateTime,
    required RepeatType repeatType,
    int? customDaysInterval,
    required bool isEnabled,
    required List<SubReminderEntity> subReminders,
  }) onSave;
  final VoidCallback? onDelete;

  /// Shows this bottom sheet in a modern modal presentation.
  static Future<void> show({
    required BuildContext context,
    ReminderEntity? existingReminder,
    List<SubReminderEntity>? existingSubReminders,
    required void Function({
      required DateTime startDateTime,
      required RepeatType repeatType,
      int? customDaysInterval,
      required bool isEnabled,
      required List<SubReminderEntity> subReminders,
    }) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ReminderPickerSheet(
          existingReminder: existingReminder,
          existingSubReminders: existingSubReminders,
          onSave: onSave,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<ReminderPickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatType _repeatType;
  late int _customDaysInterval;
  late bool _isEnabled;
  late List<SubReminderEntity> _subReminders;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReminder;
    _subReminders = List.from(widget.existingSubReminders ?? []);

    if (existing != null) {
      final local = existing.startDateTime.toLocal();
      _selectedDate = DateTime(local.year, local.month, local.day);
      _selectedTime = TimeOfDay(hour: local.hour, minute: local.minute);
      _repeatType = existing.repeatType;
      _customDaysInterval = existing.customDaysInterval ?? 2;
      _isEnabled = existing.isEnabled;
    } else {
      final now = DateTime.now().add(const Duration(hours: 1));
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _repeatType = RepeatType.none;
      _customDaysInterval = 2;
      _isEnabled = true;
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate.isBefore(now) ? now : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _applyPreset(Duration offset, {TimeOfDay? fixedTime}) {
    final target = DateTime.now().add(offset);
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _selectedTime =
          fixedTime ?? TimeOfDay(hour: target.hour, minute: target.minute);
    });
  }

  void _removeSubReminder(int index) {
    setState(() => _subReminders.removeAt(index));
  }

  void _addSubReminder(SubReminderType type,
      {int? offsetMinutes, String? exactTime}) {
    if (_subReminders.length >= SubReminderCalculator.maxSubReminders) return;

    final newSub = SubReminderEntity(
      id: const Uuid().v4(),
      reminderId: widget.existingReminder?.id ?? '',
      type: type,
      offsetMinutes: offsetMinutes,
      exactTime: exactTime,
    );

    setState(() => _subReminders.add(newSub));
  }

  Future<void> _showAddSubReminderPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.more_time_rounded,
                    color: AppColors.primaryWarmDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Sub-reminder',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Quick offsets:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('+5 min'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: 5);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ActionChip(
                    label: const Text('+10 min'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: 10);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ActionChip(
                    label: const Text('+15 min'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: 15);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ActionChip(
                    label: const Text('+30 min'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: 30);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ActionChip(
                    label: const Text('+1 hour'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: 60);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ActionChip(
                    label: const Text('10 min before'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: -10);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ActionChip(
                    label: const Text('15 min before'),
                    onPressed: () {
                      _addSubReminder(SubReminderType.offsetMinutes,
                          offsetMinutes: -15);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.primaryWarmDark,
                ),
                title: const Text('Exact time of day'),
                subtitle: const Text('e.g. 20:00 on the reminder day'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 20, minute: 0),
                  );
                  if (picked != null) {
                    final h = picked.hour.toString().padLeft(2, '0');
                    final m = picked.minute.toString().padLeft(2, '0');
                    _addSubReminder(SubReminderType.exactTime,
                        exactTime: '$h:$m');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(
      startDateTime: _combinedDateTime,
      repeatType: _repeatType,
      customDaysInterval:
          _repeatType == RepeatType.customDays ? _customDaysInterval : null,
      isEnabled: _isEnabled,
      subReminders: _subReminders,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat.yMMMEd().format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primaryWarmDark,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.existingReminder != null
                      ? 'Edit Reminder'
                      : 'Set Reminder',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cancel',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar:
                        const Icon(Icons.hourglass_bottom_rounded, size: 16),
                    label: const Text('In 1 hour'),
                    onPressed: () => _applyPreset(const Duration(hours: 1)),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                    label: const Text('Tomorrow 9 AM'),
                    onPressed: () => _applyPreset(
                      const Duration(days: 1),
                      fixedTime: const TimeOfDay(hour: 9, minute: 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.nightlight_outlined, size: 16),
                    label: const Text('Tonight 8 PM'),
                    onPressed: () => _applyPreset(
                      Duration.zero,
                      fixedTime: const TimeOfDay(hour: 20, minute: 0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Selectors
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.primaryWarmDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.primaryWarmDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recurrence selector
            DropdownButtonFormField<RepeatType>(
              value: _repeatType,
              decoration: InputDecoration(
                labelText: 'Repeat',
                prefixIcon: const Icon(Icons.repeat_rounded,
                    color: AppColors.primaryWarmDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: RepeatType.none,
                  child: Text('Does not repeat'),
                ),
                DropdownMenuItem(
                  value: RepeatType.daily,
                  child: Text('Every day'),
                ),
                DropdownMenuItem(
                  value: RepeatType.weekly,
                  child: Text('Every week'),
                ),
                DropdownMenuItem(
                  value: RepeatType.monthly,
                  child: Text('Every month'),
                ),
                DropdownMenuItem(
                  value: RepeatType.yearly,
                  child: Text('Every year'),
                ),
                DropdownMenuItem(
                  value: RepeatType.customDays,
                  child: Text('Every X days...'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _repeatType = val);
              },
            ),

            // Custom days interval field if customDays is active
            if (_repeatType == RepeatType.customDays) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('Repeat interval:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _customDaysInterval > 1
                          ? () =>
                              setState(() => _customDaysInterval -= 1)
                          : null,
                    ),
                    Text(
                      '$_customDaysInterval ${_customDaysInterval == 1 ? 'day' : 'days'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _customDaysInterval < 365
                          ? () =>
                              setState(() => _customDaysInterval += 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── Sub-reminders Section (Up to 10) ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.lightCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.more_time_rounded,
                        size: 18,
                        color: AppColors.primaryWarmDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sub-reminders (${_subReminders.length}/${SubReminderCalculator.maxSubReminders})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_subReminders.length <
                          SubReminderCalculator.maxSubReminders)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add'),
                          onPressed: () => _showAddSubReminderPicker(context),
                        ),
                    ],
                  ),
                  if (_subReminders.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'No sub-reminders. Add secondary alerts (e.g. +10 min, +30 min).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(_subReminders.length, (index) {
                        final sub = _subReminders[index];
                        final label =
                            SubReminderCalculator.formatDescription(sub);
                        return Chip(
                          backgroundColor: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          avatar: Icon(
                            sub.type == SubReminderType.exactTime
                                ? Icons.access_time_rounded
                                : Icons.snooze_rounded,
                            size: 14,
                            color: AppColors.primaryWarmDark,
                          ),
                          label: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          deleteIcon:
                              const Icon(Icons.close_rounded, size: 14),
                          onDeleted: () => _removeSubReminder(index),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active / Enabled toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder active'),
              subtitle: Text(
                _isEnabled
                    ? 'Will ring at scheduled time along with all sub-reminders'
                    : 'Paused / muted (sub-reminders also paused)',
                style: theme.textTheme.bodySmall,
              ),
              value: _isEnabled,
              activeColor: AppColors.primaryWarmDark,
              onChanged: (val) => setState(() => _isEnabled = val),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.existingReminder != null
                  ? 'Update Reminder'
                  : 'Save Reminder'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryWarmDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _save,
            ),

            if (widget.existingReminder != null && widget.onDelete != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                label: const Text(
                  'Remove Reminder & Sub-reminders',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () {
                  widget.onDelete?.call();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
