import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔵 BACKGROUND FCM: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Notifications for important events',
    importance: Importance.high,
  );

  static String? _token;

  static String? get token => _token;

  static final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  static Stream<String> get onTokenRefresh => _tokenController.stream;

  static Future<String?> init() async {
    debugPrint('🟡 FCM: init() STARTED');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // -----------------------------
    // Notification permission
    // -----------------------------

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🟢 FCM: permission = ${settings.authorizationStatus}');

    // -----------------------------
    // Local notifications
    // -----------------------------

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: initializationSettings);

    // Create Android notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // -----------------------------
    // FCM token
    // -----------------------------

    debugPrint('🟡 FCM: getting token...');

    final token = await messaging.getToken();

    _token = token;

    debugPrint('🟢🟢🟢 FCM TOKEN: $token');

    // -----------------------------
    // Token refresh
    // -----------------------------

    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM: token refreshed: $newToken');

      _token = newToken;

      _tokenController.add(newToken);
    });

    // -----------------------------
    // Foreground messages
    // -----------------------------

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🟣 FOREGROUND FCM: ${message.messageId}');

      debugPrint('🟣 Title: ${message.notification?.title}');

      debugPrint('🟣 Body: ${message.notification?.body}');

      debugPrint('🟣 Data: ${message.data}');

      final notification = message.notification;

      if (notification != null) {
        await _showLocalNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });

    debugPrint('🟢 FCM: init() FINISHED');

    return token;
  }

  // -----------------------------
  // Local notification
  // -----------------------------

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Notifications for important events',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
