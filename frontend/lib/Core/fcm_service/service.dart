import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:swaransh_academy/Core/theme/app_colors.dart';

import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔵 BACKGROUND FCM: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Importance.max + Priority.max forces the heads-up banner on Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel_v2', // Changed ID to force recreation of the channel
    'High Importance Notifications',
    description: 'Notifications for important events',
    importance: Importance.max,
  );

  static String? _token;
  static String? get token => _token;
  static set token(String? value) => _token = value;
  static final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  static Stream<String> get onTokenRefresh => _tokenController.stream;

  static Future<String?> init() async {
    debugPrint('🟡 FCM: init() STARTED');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // 1. Enable iOS foreground banners explicitly
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🟢 FCM: permission = ${settings.authorizationStatus}');

    // 3. Local notifications init (Android + iOS Darwin settings)
    const androidSettings = AndroidInitializationSettings('ic_notification');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: initializationSettings);

    // Create Android notification channel
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);

    // Android 13+ runtime permission
    await androidPlugin?.requestNotificationsPermission();

    // Fetch Token
    final token = await messaging.getToken();
    _token = token;
    debugPrint('🟢🟢🟢 FCM TOKEN: $token');

    messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _tokenController.add(newToken);
    });

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🟣 FOREGROUND FCM: ${message.messageId}');

      final notification = message.notification;

      if (notification != null) {
        await _showLocalNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });

    return token;
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel_v2', // Matches channel ID above
      'High Importance Notifications',
      channelDescription: 'Notifications for important events',
      icon: 'ic_notification',
      color: AppColors.ivory,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
