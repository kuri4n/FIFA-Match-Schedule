import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation('Asia/Kolkata'),
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    final androidImpl = _notifications
      .resolvePlatformSpecificImplementation
          <AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    
  }

  static Future<void> scheduleMatchReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }


    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'match_reminders',
          'Match Reminders',
          channelDescription: 'Notifications for upcoming FIFA matches',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test Notification',
      'If you see this, notifications are working',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'match_reminders',
          'Match Reminders',
          channelDescription: 'Notifications for upcoming FIFA matches',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
  static Future<void> schedule15MinReminder({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required DateTime matchTime,
  }) async {
    await scheduleMatchReminder(
      id: matchId * 10 + 15,
      title: 'Match starts in 15 minutes',
      body: '$homeTeam vs $awayTeam starts soon!',
      scheduledTime: matchTime.toLocal().subtract(
        const Duration(minutes: 15),
      ),
    );
  }

  static Future<void> schedule1HourReminder({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required DateTime matchTime,
  }) async {
    await scheduleMatchReminder(
      id: matchId * 10 + 60,
      title: 'Match starts in 1 hour',
      body: '$homeTeam vs $awayTeam starts in 1 hour.',
      scheduledTime: matchTime.toLocal().subtract(
        const Duration(hours: 1),
      ),
    );
  }

}