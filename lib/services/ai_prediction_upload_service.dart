import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_service.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_data.dart';
import 'package:glucora_ai_companion/services/repositories/prediction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiPredictionUploadService {
  AiPredictionUploadService._();
  static final AiPredictionUploadService instance =
      AiPredictionUploadService._();

  StreamSubscription<BleHardwareData>? _subscription;

  final PredictionRepository _predictionRepo =
      PredictionRepository(Supabase.instance.client);

  void startListening() {
    if (_subscription != null) {
      if (kDebugMode) {
        print('[AiPredictionUploadService] Already listening to BLE data.');
      }
      return;
    }

    if (kDebugMode) {
      print('[AiPredictionUploadService] Starting to listen for AI predictions...');
    }

    _subscription =
        BleHardwareService.instance.dataStream.listen((data) async {
      if (data.predictionValue != null) {
        if (kDebugMode) {
          print(
            '[AiPredictionUploadService] Found new prediction: ${data.predictionValue}. Uploading...',
          );
        }

        final success =
            await _predictionRepo.insert(data.predictionValue!);

        if (kDebugMode) {
          if (success) {
            print(
              '[AiPredictionUploadService] Successfully uploaded prediction: ${data.predictionValue}',
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

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    if (kDebugMode) {
      print('[AiPredictionUploadService] Stopped listening for AI predictions.');
    }
  }
}