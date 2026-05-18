import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  static final FlutterLocalNotificationsPlugin
      localNotifications =
      FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  static Future<void> initialize() async {

    // ANDROID SETTINGS
    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await localNotifications.initialize(
      settings,
    );

    // REQUEST PERMISSION
    await FirebaseMessaging.instance
        .requestPermission();

    // FOREGROUND MESSAGE
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {

        showNotification(
          title:
              message.notification?.title ??
                  "Notification",

          body:
              message.notification?.body ??
                  "",
        );
      },
    );
  }

  // ================= SHOW =================
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {

    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(
      'ride_channel',
      'Ride Notifications',

      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );

    await localNotifications.show(
      0,
      title,
      body,
      details,
    );
  }

  // ================= GET TOKEN =================
  static Future<String?> getToken() async {

    return await FirebaseMessaging.instance
        .getToken();
  }
}