import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'database_service.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _dailyId = 1;
  static const _streakId = 2;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(name);
      tz.setLocalLocation(location);
    } catch (e) {
      // Fallback to a guaranteed location constant; never let init throw.
      tz.setLocalLocation(tz.UTC);
      debugPrint('NotificationService: timezone fallback to UTC due to $e');
    }

    // Use a dedicated monochrome small icon to ensure it renders in the status bar.
    const android = AndroidInitializationSettings('ic_stat_minnalearn');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  Future<bool> requestPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<bool> _isEnabled() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  Future<void> rescheduleAll() async {
    if (!await _isEnabled()) {
      debugPrint('Notifications disabled; skipping schedule.');
      return;
    }
    await _notifications.cancel(_dailyId);
    await _notifications.cancel(_streakId);
    await _scheduleDaily();
    await _scheduleStreakIfNeeded();
  }

  Future<void> _scheduleDaily() async {
    await _notifications.zonedSchedule(
      _dailyId,
      'MinnaLearn',
      'Time to continue your Japanese journey!',
      _next(18, 0), // 6 PM
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

  Future<void> _scheduleStreakIfNeeded() async {
    final db = DatabaseService();
    final rows = await (await db.database).query(
      'user_stats',
      where: 'key = ?',
      whereArgs: ['last_study_date'],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final value = (rows.first['value_text'] as String?) ?? '';
    final dateStr = value.contains('T') ? value.split('T').first : value;
    final last = DateTime.tryParse(dateStr);
    if (last == null) return;

    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;

    if (diff == 1) {
      await _notifications.zonedSchedule(
        _streakId,
        'MinnaLearn 🔥',
        'Don’t lose your streak! Come back today!',
        _next(20, 0), // 8 PM
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminder',
            'Streak Reminders',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFFFF5252),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await _notifications.cancel(_streakId);
    }
  }

  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var time = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (time.isBefore(now)) time = time.add(const Duration(days: 1));
    return time;
  }
}
