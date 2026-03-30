import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'habits_reminders';
  static const _channelName = 'Habit Reminders';
  static const _channelDescription =
      'Daily reminder notifications for your habits';

  static bool _initialized = false;
  static bool _pluginAvailable = true;
  static bool get _supportsNotifications {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    if (!_supportsNotifications) {
      tz.setLocalLocation(tz.UTC);
      _pluginAvailable = false;
      _initialized = true;
      return;
    }

    var timezoneName = 'UTC';
    try {
      timezoneName = await FlutterTimezone.getLocalTimezone();
    } on MissingPluginException {
      // Falls back to UTC when timezone plugin is unavailable.
    }
    final location = tz.timeZoneDatabase.locations[timezoneName] ?? tz.UTC;
    tz.setLocalLocation(location);

    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    try {
      await _plugin.initialize(settings);
    } on MissingPluginException {
      _pluginAvailable = false;
      _initialized = true;
      return;
    }

    final iOS = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    try {
      await iOS?.requestPermissions(alert: true, badge: false, sound: true);
    } on MissingPluginException {
      _pluginAvailable = false;
      _initialized = true;
      return;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await android?.requestNotificationsPermission();
    } on MissingPluginException {
      _pluginAvailable = false;
      _initialized = true;
      return;
    }

    _initialized = true;
  }

  static int _idFor(String habitId) {
    var hash = 0;
    for (final unit in habitId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static Future<void> schedule(Habit habit) async {
    await init();
    if (!_pluginAvailable) return;
    final id = _idFor(habit.id);
    await _plugin.cancel(id);
    if (!habit.hasReminder) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      habit.reminderHour!,
      habit.reminderMinute ?? 0,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      habit.name,
      'Time to complete your habit!',
      scheduled,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(String habitId) async {
    await init();
    if (!_pluginAvailable) return;
    await _plugin.cancel(_idFor(habitId));
  }

  static Future<void> syncAll(Iterable<Habit> habits) async {
    for (final habit in habits) {
      await schedule(habit);
    }
  }
}
