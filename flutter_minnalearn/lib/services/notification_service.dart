import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _notificationsGranted = false;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    // Set the local timezone from the device
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone, using UTC: $e');
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(initializationSettings);

    // Request notification permission on Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      _notificationsGranted =
          await androidPlugin.requestNotificationsPermission() ?? true;
    } else {
      _notificationsGranted = true;
    }
  }

  Future<void> scheduleAllNotifications() async {
    if (!_notificationsGranted) {
      debugPrint('Notification permission not granted; skipping scheduling.');
      return;
    }

    // 1. Always schedule Daily Reminder (6 PM)
    await _scheduleDailyReminder();
    
    // 2. Conditionally schedule Streak Reminder (8 PM)
    final db = DatabaseService();
    final lastStudyResult = await (await db.database).query('user_stats', where: 'key = ?', whereArgs: ['last_study_date']);
    String lastDateStr = lastStudyResult.isNotEmpty ? (lastStudyResult.first['value_text'] as String? ?? '') : '';
    
    if (lastDateStr.isNotEmpty) {
      // Normalize: extract just the date part (handles both "2026-03-28" and "2026-03-28T19:59:04.123")
      String normalized = lastDateStr.contains('T') ? lastDateStr.split('T')[0] : lastDateStr;
      DateTime lastDate = DateTime.parse(normalized);
      if (shouldSendStreakReminder(lastDate)) {
        await _scheduleStreakReminder();
      } else {
        // Cancel if already scheduled but now not needed (e.g., user just studied)
        await _notifications.cancel(2);
      }
    }
  }

  bool shouldSendStreakReminder(DateTime lastStudyDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final lastOnly = DateTime(lastStudyDate.year, lastStudyDate.month, lastStudyDate.day);
    final diff = todayOnly.difference(lastOnly).inDays;

    // missed yesterday (diff == 1) → danger
    return diff == 1;
  }

  Future<void> _scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      1, // ID 1 for Daily
      'MinnaLearn',
      'Time to continue your Japanese journey! 🇯🇵',
      _nextInstanceOfTime(18, 0), // 6 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleStreakReminder() async {
    await _notifications.zonedSchedule(
      2, // ID 2 for Streak
      'MinnaLearn 🔥',
      'Don’t lose your streak! Come back today!',
      _nextInstanceOfTime(20, 0), // 8 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Streak Reminders',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFFF5252), // Fire red
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
