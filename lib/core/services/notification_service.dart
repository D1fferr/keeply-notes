import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Service managing local notifications, timezone initialization, native notification
/// channels for Android, and permission handling for iOS and Android.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String?> _notificationTapController =
      StreamController<String?>.broadcast();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Stream of notification payloads emitted when a notification is tapped.
  Stream<String?> get onNotificationTap => _notificationTapController.stream;

  /// Underlying plugin instance (useful for advanced extensions).
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  // ─── Channels ─────────────────────────────────────────────────────────────

  static const AndroidNotificationChannel primaryReminderChannel =
      AndroidNotificationChannel(
    AppConstants.primaryReminderChannelId,
    AppConstants.primaryReminderChannelName,
    description: AppConstants.primaryReminderChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel subReminderChannel =
      AndroidNotificationChannel(
    AppConstants.subReminderChannelId,
    AppConstants.subReminderChannelName,
    description: AppConstants.subReminderChannelDesc,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Initializes timezone database and configures platform-specific notification plugins.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('Initializing NotificationService & Timezones...');

      // 1. Initialize timezones
      tz.initializeTimeZones();

      // 2. Platform initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // 3. Initialize plugin
      final initialized = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.debug(
              'Notification tapped with payload: ${response.payload}');
          _notificationTapController.add(response.payload);
        },
      );

      AppLogger.debug('FlutterLocalNotifications initialized: $initialized');

      // 4. Create Android Notification Channels natively
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation
            .createNotificationChannel(primaryReminderChannel);
        await androidImplementation
            .createNotificationChannel(subReminderChannel);
        AppLogger.info('Native Android notification channels created successfully.');
      }

      _isInitialized = true;
      AppLogger.info('NotificationService initialized successfully.');
    } catch (e, st) {
      AppLogger.error('Failed to initialize NotificationService', e, st);
      rethrow;
    }
  }

  // ─── Permissions ──────────────────────────────────────────────────────────

  /// Requests notification permissions for Android (13+) and iOS.
  ///
  /// Returns `true` if permissions were granted or already enabled.
  Future<bool> requestPermissions() async {
    try {
      // iOS permissions
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        AppLogger.info('iOS notification permissions granted: $granted');
        return granted ?? false;
      }

      // Android permissions (Android 13+ POST_NOTIFICATIONS & exact alarms)
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final notificationGranted =
            await androidImplementation.requestNotificationsPermission();
        final exactAlarmGranted =
            await androidImplementation.requestExactAlarmsPermission();

        AppLogger.info(
            'Android notification permission: $notificationGranted, exact alarm permission: $exactAlarmGranted');
        return notificationGranted ?? true;
      }

      return true;
    } catch (e, st) {
      AppLogger.error('Failed to request notification permissions', e, st);
      return false;
    }
  }

  // ─── Timezone conversion helper ───────────────────────────────────────────

  /// Converts a standard [DateTime] to a timezone-aware [tz.TZDateTime]
  /// in the local location.
  tz.TZDateTime toZonedTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }

  // ─── Scheduling & Presentation ────────────────────────────────────────────

  /// Shows an immediate notification.
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isSubReminder = false,
  }) async {
    final channel = isSubReminder ? subReminderChannel : primaryReminderChannel;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedules a notification for a future trigger time using timezone-aware calculation.
  Future<void> scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    bool isSubReminder = false,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final channel = isSubReminder ? subReminderChannel : primaryReminderChannel;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );

    AppLogger.debug(
        'Scheduled notification $id for $scheduledDate (payload: $payload)');
  }

  /// Cancels a scheduled or active notification by [id].
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    AppLogger.debug('Cancelled notification $id');
  }

  /// Cancels all scheduled and active notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    AppLogger.info('Cancelled all notifications.');
  }

  /// Returns all currently scheduled pending notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  void dispose() {
    _notificationTapController.close();
  }
}
