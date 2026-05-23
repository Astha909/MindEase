import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart'
as tz;
import 'package:timezone/data/latest.dart'
as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin
  _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings =
    InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
    );
  }

  Future<void> showDailyReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails =
    AndroidNotificationDetails(
      'daily_checkin_channel',
      'Daily Check-In',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails =
    NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(
        hour: 21,
        minute: 0,
      ),
      notificationDetails,
      androidScheduleMode:
      AndroidScheduleMode
          .exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation
          .absoluteTime,
      matchDateTimeComponents:
      DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(
      int id,
      ) async {
    await _notifications.cancel(id);
  }

  tz.TZDateTime _nextInstanceOfTime({
    required int hour,
    required int minute,
  }) {
    final now =
    tz.TZDateTime.now(
      tz.local,
    );

    var scheduledDate =
    tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate =
          scheduledDate.add(
            const Duration(days: 1),
          );
    }

    return scheduledDate;
  }
}