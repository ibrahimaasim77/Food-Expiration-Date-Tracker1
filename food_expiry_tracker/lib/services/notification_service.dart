import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/food_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> scheduleExpiryNotifications(FoodItem item) async {
    if (kIsWeb || item.id == null) return;

    await _scheduleNotification(
      id: item.id! * 10,
      title: 'Expiring Soon',
      body: '${item.name} expires in 3 days!',
      scheduledDate: item.expiryDate.subtract(const Duration(days: 3)),
    );

    await _scheduleNotification(
      id: item.id! * 10 + 1,
      title: 'Expires Tomorrow',
      body: '${item.name} expires tomorrow!',
      scheduledDate: item.expiryDate.subtract(const Duration(days: 1)),
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const darwinDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry Notifications',
          channelDescription: 'Notifications for food expiry dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotifications(int itemId) async {
    if (kIsWeb) return;
    await _notifications.cancel(itemId * 10);
    await _notifications.cancel(itemId * 10 + 1);
  }

  /// Request notification permission on Android 13+.
  /// iOS permission is requested automatically via DarwinInitializationSettings.
  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Reschedule notifications for all upcoming items (call on app launch).
  static Future<void> rescheduleAll(List<FoodItem> items) async {
    if (kIsWeb) return;
    for (final item in items) {
      if (item.id != null) {
        await scheduleExpiryNotifications(item);
      }
    }
  }
}
