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

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleMatchReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Notification not scheduled because time is in the past');
      return;
    }

    print('Scheduling notification for: $scheduledTime');

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'match_reminders',
          'Match Reminders',
          channelDescription: 'Notifications for upcoming FIFA matches',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleTestReminder() async {
    await scheduleMatchReminder(
      id: 1000,
      title: 'Test Scheduled Reminder',
      body: 'This scheduled notification is working',
      scheduledTime: DateTime.now().add(
        const Duration(seconds: 30),
      ),
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
}