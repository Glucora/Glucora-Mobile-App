import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    severity: message.data['severity'] ?? 'warning',
  );
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _criticalChannel = AndroidNotificationChannel(
    'glucose_critical',
    'Critical Glucose Alerts',
    description: 'Critical high and low glucose alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const _warningChannel = AndroidNotificationChannel(
    'glucose_warning',
    'Glucose Warnings',
    description: 'High and low glucose warnings',
    importance: Importance.high,
    playSound: true,
  );

  static Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (details) {
        // handle tap on notification when app is in foreground
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_criticalChannel);
    await androidPlugin?.createNotificationChannel(_warningChannel);

    // STATE 1 — Foreground
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        severity: message.data['severity'] ?? 'warning',
      );
    });

    // STATE 2 — Background (app open but in background), user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // app is already open, handle navigation here if needed
      showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        severity: message.data['severity'] ?? 'warning',
      );
    });

    // STATE 3 — Killed (app was closed), check if launched from notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      showLocalNotification(
        title: initialMessage.notification?.title ?? '',
        body: initialMessage.notification?.body ?? '',
        severity: initialMessage.data['severity'] ?? 'warning',
      );
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  static Future<void> saveTokenToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    await Supabase.instance.client.from('device_tokens').upsert({
      'user_id': user.id,
      'fcm_token': token,
      'platform': 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, fcm_token');

    _fcm.onTokenRefresh.listen((newToken) async {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'fcm_token': newToken,
        'platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');
    });
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    required String severity,
  }) async {
    final isCritical = severity == 'critical';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isCritical ? _criticalChannel.id : _warningChannel.id,
        isCritical ? _criticalChannel.name : _warningChannel.name,
        importance: isCritical ? Importance.max : Importance.high,
        priority: Priority.max,
        color: isCritical ? const Color(0xFFE53935) : const Color(0xFFFFA726),
        enableLights: true,
        ledColor: isCritical ? const Color(0xFFE53935) : const Color(0xFFFFA726),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}