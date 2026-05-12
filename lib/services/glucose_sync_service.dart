import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_service.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_data.dart';
import 'package:glucora_ai_companion/services/repositories/glucose_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs glucose readings from BLE hardware to Supabase database.
///
/// This service listens to BLE data stream and automatically uploads
/// glucose readings to the database for historical tracking.
class GlucoseSyncService {
  GlucoseSyncService._();
  static final GlucoseSyncService instance = GlucoseSyncService._();

  StreamSubscription<BleHardwareData>? _subscription;
  final GlucoseRepository _glucoseRepo = GlucoseRepository(
    Supabase.instance.client,
  );

  // Track recent values to avoid duplicate uploads
  DateTime? _lastSyncTime;
  double? _lastSyncedValue;
  static const Duration _syncDebounce = Duration(minutes: 2);

  void startListening() {
    if (_subscription != null) {
      if (kDebugMode) {
        print('[GlucoseSyncService] Already listening to BLE data.');
      }
      return;
    }

    if (kDebugMode) {
      print('[GlucoseSyncService] Starting glucose sync service...');
    }

    _subscription = BleHardwareService.instance.dataStream.listen((data) async {
      // Only sync glucose readings, not predictions
      if (data.latestGlucoseValue != null && data.isConnected) {
        final now = DateTime.now();

        // Debounce: only sync if enough time has passed or value changed significantly
        final shouldSync =
            _lastSyncTime == null ||
            now.difference(_lastSyncTime!).compareTo(_syncDebounce) >= 0 ||
            (_lastSyncedValue != null &&
                (data.latestGlucoseValue! - _lastSyncedValue!).abs() > 5);

        if (shouldSync) {
          if (kDebugMode) {
            print(
              '[GlucoseSyncService] Syncing glucose reading: ${data.latestGlucoseValue} mg/dL',
            );
          }

          try {
            final user = Supabase.instance.client.auth.currentUser;
            if (user == null) {
              if (kDebugMode) {
                print(
                  '[GlucoseSyncService] No authenticated user. Skipping sync.',
                );
              }
              return;
            }

            // Get patient profile ID
            final patientProfileId = await _glucoseRepo.getPatientProfileId(
              user.id,
            );
            if (patientProfileId == null) {
              if (kDebugMode) {
                print('[GlucoseSyncService] No patient profile found.');
              }
              return;
            }

            // Insert the glucose reading
            await Supabase.instance.client.from('glucose_readings').insert({
              'patient_id': patientProfileId,
              'value_mg_dl': data.latestGlucoseValue,
              'source': 'ble_sensor',
              'trend': 'stable',
              'is_predicted': false,
              'recorded_at': DateTime.now().toIso8601String(),
            });

            _lastSyncTime = now;
            _lastSyncedValue = data.latestGlucoseValue;

            if (kDebugMode) {
              print(
                '[GlucoseSyncService] ✓ Successfully synced: ${data.latestGlucoseValue} mg/dL',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('[GlucoseSyncService] Failed to sync glucose reading: $e');
            }
          }
        } else {
          if (kDebugMode) {
            print(
              '[GlucoseSyncService] Skipping sync (debounce): ${data.latestGlucoseValue} mg/dL',
            );
          }
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _lastSyncTime = null;
    _lastSyncedValue = null;
    if (kDebugMode) {
      print('[GlucoseSyncService] Stopped listening for glucose readings.');
    }
  }
}
