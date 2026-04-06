// lib\services\location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final _supabase = Supabase.instance.client;
  static bool _running = false;

  static Future<void> startSharingLocation(String userId) async {
    if (_running) {
      print("Location already running");
      return;
    }

    // Ask for permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      print("Permission permanently denied");
      return;
    }

    _running = true;
    print("LOCATION UPDATE LOOP RUNNING");
    // Send location every 10 seconds
    while (_running) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print("Sending: ${position.latitude}, ${position.longitude}");

        await _supabase.from('patient_locations').upsert({
          'patient_id': userId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'sharing_enabled': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'patient_id');
      } catch (e) {
        print('Location error: $e');
      }

      await Future.delayed(const Duration(seconds: 10));
    }
  }

  static void stopSharingLocation() {
    _running = false;
  }
}
