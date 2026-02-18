import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings, // ✅ REQUIRED NOW
      onDidReceiveNotificationResponse: (response) {},
    );
  }

  static Future<void> send(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Cold Chain Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> requestPermission() async {
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static Future<void> sendRepeated(
    String title,
    String body, {
    int times = 5,
    Duration gap = const Duration(seconds: 5),
  }) async {
    for (int i = 0; i < times; i++) {
      await send(title, body);
      await Future.delayed(gap);
    }
  }
}
