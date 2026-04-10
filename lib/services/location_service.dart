import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  static Future<void> initializeService() async {
     if (kIsWeb) {
      print('Location service disabled on web');
      return;
    }
    if (Platform.isAndroid) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'my_foreground',
        'Glucora Location Service',
        description: 'Used for background location tracking',
        importance: Importance.low,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Glucora Tracking',
        initialNotificationContent: 'Active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static void startSharingLocation(String userId) async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    service.invoke("setUserId", {"userId": userId});
  }

  static void stopSharingLocation() {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await Supabase.initialize(
    url: "https://yzmkzfqgigsaqhnbsiyn.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bWt6ZnFnaWdzYXFobmJzaXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTY4NzAsImV4cCI6MjA4OTMzMjg3MH0.Z0xEWSa3qbd0KDHgFQfCFJ8Y7EoYfeiNxKRm0mQCsRE",
  );

  final supabase = Supabase.instance.client;
  String? currentUserId;
  StreamSubscription<Position>? positionStream;

  service.on('setUserId').listen((event) {
    currentUserId = event?['userId'];
  });

  service.on('stopService').listen((event) {
    positionStream?.cancel();
    service.stopSelf();
  });

  positionStream = Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 10),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Patient tracking is active",
        notificationTitle: "Glucora Live",
        enableWakeLock: true,
      ),
    ),
  ).listen((Position position) async {
    if (currentUserId == null) return;

    try {
      await supabase.from('patient_locations').upsert({
        'patient_id': currentUserId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'sharing_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'patient_id');
    } catch (e) {
      // ignore: avoid_print
      print("Background Error: $e");
    }
  });
}