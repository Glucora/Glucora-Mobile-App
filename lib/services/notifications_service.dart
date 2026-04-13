import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ─── Background handler (top-level, NOT a class method) ───────────────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(android: androidSettings),
  );
  await _showWithPlugin(
    plugin,
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    severity: message.data['severity'] ?? 'warning',
  );
}

// Shared helper — works both inside and outside the class.
Future<void> _showWithPlugin(
  FlutterLocalNotificationsPlugin plugin, {
  required String title,
  required String body,
  required String severity,
}) async {
  final isCritical = severity == 'critical';
  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        isCritical ? 'glucose_critical' : 'glucose_warning',
        isCritical ? 'Critical Glucose Alerts' : 'Glucose Warnings',
        importance: isCritical ? Importance.max : Importance.high,
        priority: Priority.max,
        color: isCritical ? const Color(0xFFE53935) : const Color(0xFFFFA726),
        enableLights: true,
        ledColor: isCritical
            ? const Color(0xFFE53935)
            : const Color(0xFFFFA726),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        enableVibration: isCritical,
      ),
    ),
  );
}

// ─── Unified NotificationService ─────────────────────────────────────────────
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _fcm = FirebaseMessaging.instance;

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

  static const _medicationChannel = AndroidNotificationChannel(
    'medication_reminders',
    'Medication Reminders',
    description: 'Daily medication reminders',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ── Initialize ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final match = tz.timeZoneDatabase.locations.values.firstWhere((loc) {
        final zones = loc.zones;
        return zones.isNotEmpty && zones.last.offset == offsetMinutes * 60;
      }, orElse: () => tz.getLocation('UTC'));
      tz.setLocalLocation(match);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_criticalChannel);
    await androidPlugin?.createNotificationChannel(_warningChannel);
    await androidPlugin?.createNotificationChannel(_medicationChannel);
    await androidPlugin?.requestNotificationsPermission();

    FirebaseMessaging.onMessage.listen((message) {
      showGlucoseNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        severity: message.data['severity'] ?? 'warning',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) print('Opened from background: ${message.data}');
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) print('Launched from terminated: ${initialMessage.data}');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  // ── FCM token ──────────────────────────────────────────────────────────────
  static Future<void> saveTokenToSupabase() async {
    if (kIsWeb) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    Future<void> upsert(String token) =>
        Supabase.instance.client.from('device_tokens').upsert({
          'user_id': user.id,
          'fcm_token': token,
          'platform': 'android',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, fcm_token');

    final token = await _fcm.getToken();
    if (token != null) await upsert(token);

    _fcm.onTokenRefresh.listen(upsert);
  }

  // ── Glucose alert (immediate) ──────────────────────────────────────────────
  static Future<void> showGlucoseNotification({
    required String title,
    required String body,
    required String severity,
  }) async {
    if (kIsWeb) return;
    await _showWithPlugin(
      _plugin,
      title: title,
      body: body,
      severity: severity,
    );
  }

  // ── Medication reminder (scheduled, daily recurring) ──────────────────────
  // FIX: On Android 12+ the SCHEDULE_EXACT_ALARM permission must be granted
  //      by the user in Settings. If it hasn't been granted, scheduling with
  //      exactAllowWhileIdle throws a PlatformException. We catch that and
  //      fall back to inexact scheduling so the app never crashes.
  static Future<void> scheduleReminder({
    required int id,
    required String medName,
    required String remindAt, // "HH:MM:SS" or "HH:MM"
  }) async {
    if (kIsWeb) return;

    final parts = remindAt.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Daily medication reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Try exact alarm first; fall back to inexact if permission is denied.
    try {
      await _plugin.zonedSchedule(
        id,
        '💊 Medication Reminder',
        'Time to take $medName',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (kDebugMode) print('Scheduled exact alarm for $medName at $remindAt');
    } catch (e) {
      // SCHEDULE_EXACT_ALARM not granted — use inexact (still fires, just not
      // guaranteed to the exact second).
      if (kDebugMode) {
        print('Exact alarm failed ($e) — falling back to inexact for $medName');
      }
      try {
        await _plugin.zonedSchedule(
          id,
          '💊 Medication Reminder',
          'Time to take $medName',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        if (kDebugMode) {
          print('Scheduled inexact alarm for $medName at $remindAt');
        }
      } catch (e2) {
        // Notifications are completely blocked — log and move on.
        if (kDebugMode) print('Notification scheduling failed entirely: $e2');
      }
    }
  }

  // ── Cancel helpers ─────────────────────────────────────────────────────────
  static Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll(List<int> ids) async {
    if (kIsWeb) return;
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }
}
