import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:glucora_ai_companion/services/ble/ble_hardware_service.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_data.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';

class AiPredictionUploadService {
  AiPredictionUploadService._();
  static final AiPredictionUploadService instance =
      AiPredictionUploadService._();

  StreamSubscription<BleHardwareData>? _subscription;

  /// Starts listening to the BLE hardware stream and auto-uploads any new predictions to Supabase.
  void startListening() {
    if (_subscription != null) {
      if (kDebugMode) {
        print('[AiPredictionUploadService] Already listening to BLE data.');
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[AiPredictionUploadService] Starting to listen for AI predictions...',
      );
    }

    _subscription = BleHardwareService.instance.dataStream.listen((data) async {
      if (data.predictionValue != null) {
        if (kDebugMode) {
          print(
            '[AiPredictionUploadService] Found new prediction: ${data.predictionValue}. Uploading...',
          );
        }

        // As requested by the user, every emission gets uploaded directly.
        final success = await insertAiPrediction(data.predictionValue!);
        if (kDebugMode) {
          if (success) {
            print(
              '[AiPredictionUploadService] Successfully uploaded valid prediction: ${data.predictionValue}',
            );
          } else {
            print(
              '[AiPredictionUploadService] Failed to upload prediction: ${data.predictionValue}',
            );
          }
        }
      }
    });
  }

  /// Stops tracking hardware predictions and cleans up the active subscription.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    if (kDebugMode) {
      print(
        '[AiPredictionUploadService] Stopped listening for AI predictions.',
      );
    }
  }
}