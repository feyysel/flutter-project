import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Pure-Supabase notification delivery:
/// Supabase Realtime streams push new rows into [showLocal], which raises a
/// real system (heads-up) notification while the app is running, foreground
/// or background. No Firebase involved.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String?> _tapController =
      StreamController<String?>.broadcast();

  static bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ride_channel',
    'Ride Notifications',
    description: 'Ride requests, acceptances and account updates',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _tapController.add(response.payload),
    );

    await _createAndroidChannel();
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _createAndroidChannel() async {
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_channel',
      'Ride Notifications',
      channelDescription: 'Ride requests, acceptances and account updates',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      ticker: 'DriveOn',
    );
    const details = NotificationDetails(android: androidDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  static Stream<String?> get onNotificationTap => _tapController.stream;
}
