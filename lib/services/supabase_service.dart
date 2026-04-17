// lib\services\supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:glucora_ai_companion/core/models/glucose_log_model.dart';

final _db = Supabase.instance.client;

// ─── PATIENT PROFILE ──────────────────────────────────────────────────────────

/// Returns patient_profile.id for the given Supabase Auth user id.
/// This is DIFFERENT from auth user id — always call this first.
Future<int?> getPatientProfileId(String authUserId) async {
  try {
    final row = await _db
        .from('patient_profile')
        .select('id')
        .eq('user_id', authUserId)
        .maybeSingle();

    if (row == null) return null;
    return row['id'] as int;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getPatientProfileId error: $e');
    return null;
  }
}

// ─── GLUCOSE ──────────────────────────────────────────────────────────────────

/// Returns the most recent glucose reading row for this patient.
Future<Map<String, dynamic>?> getLatestGlucoseReading(
  int patientProfileId,
) async {
  try {
    final response = await _db
        .from('glucose_readings')
        .select('id, patient_id, value_mg_dl, recorded_at, trend, source')
        .eq('patient_id', patientProfileId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (kDebugMode) {
      print('[SupabaseService] glucose query response: $response');
    }
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseService] getLatestGlucoseReading error: $e');
    }
    return null;
  }
}

// ─── AI PREDICTIONS ───────────────────────────────────────────────────────────

/// Returns the most recent LSTM prediction row for this patient.
Future<Map<String, dynamic>?> getLatestPrediction(int patientProfileId) async {
  try {
    final response = await _db
        .from('ai_predictions')
        .select()
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getLatestPrediction error: $e');
    return null;
  }
}


/// Fetch the latest `limit` recommendations for a patient.
Future<List<Map<String, dynamic>>> getLatestRecommendations({
  required int patientProfileId,
  int limit = 3, // fetch latest 3
}) async {
  try {
    final response = await _db
        .from('ai_recommendations')
        .select()
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseService] getLatestRecommendations error: $e');
    }
    return [];
  }
}

// ─── AI RECOMMENDATIONS ───────────────────────────────────────────────────────

/// Save a single recommendation row and return it for immediate display.
/// [patientProfileId] = patient_profile.id (NOT auth user id).
Future<Map<String, dynamic>?> saveRecommendation({
  required int patientProfileId,
  required String category,
  required String message,
  String? predictionId,
}) async {
  try {
    final row = {
      'patient_id': patientProfileId,
      'category': category,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (predictionId != null) row['prediction_id'] = predictionId;

    final response = await _db
        .from('ai_recommendations')
        .insert(row)
        .select()
        .single();

    if (kDebugMode) {
      print('[SupabaseService] Saved recommendation: ${response['id']}');
    }
    return response;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] saveRecommendation error: $e');
    return null;
  }
}

/// Fetch only the latest `limit` recommendations for display.
Future<List<Map<String, dynamic>>> getLatestRecommendation({
  required int patientProfileId,
  int limit = 20,
}) async {
  try {
    final response = await _db
        .from('ai_recommendations')
        .select()
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseService] getLatestRecommendations error: $e');
    }
    return [];
  }
}

/// Mark recommendation as read.
Future<bool> markRecommendationAsRead(String recommendationId) async {
  try {
    await _db
        .from('ai_recommendations')
        .update({'is_read': true})
        .eq('id', recommendationId);

    return true;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseService] markRecommendationAsRead error: $e');
    }
    return false;
  }
}

/// Delete recommendation.
Future<bool> deleteRecommendation(String recommendationId) async {
  try {
    await _db.from('ai_recommendations').delete().eq('id', recommendationId);

    return true;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] deleteRecommendation error: $e');
    return false;
  }
}

/// Count unread recommendations.
Future<int> getUnreadCount(int patientProfileId) async {
  try {
    final response = await _db
        .from('ai_recommendations')
        .select('id')
        .eq('patient_id', patientProfileId)
        .eq('is_read', false);

    return (response as List).length;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getUnreadCount error: $e');
    return 0;
  }
}

// ─── MANUAL GLUCOSE LOG ───────────────────────────────────────────────────────

/// Fetch all glucose readings for the current patient, newest first.
Future<List<GlucoseLog>> fetchGlucoseLogs() async {
  final userId = _db.auth.currentUser!.id;
  final patientId = await getPatientProfileId(userId);
  if (patientId == null) return [];

  final response = await _db
      .from('glucose_readings')
      .select()
      .eq('patient_id', patientId)
      .order('recorded_at', ascending: false);

  return (response as List).map((e) => GlucoseLog.fromJson(e)).toList();
}

/// Insert a manual glucose reading for the current patient.
Future<void> insertGlucoseLog(
  double value,
  String? notes,
  String mealTime,
) async {
  final userId = _db.auth.currentUser!.id;
  final patientId = await getPatientProfileId(userId);
  if (patientId == null) return;

  await _db.from('glucose_readings').insert({
    'value_mg_dl': value,
    'source': 'manual',
    'trend': 'stable',
    'patient_id': patientId,
    'is_predicted': false,
    'meal_time': mealTime,
    if (notes != null && notes.isNotEmpty) 'notes': notes,
    'recorded_at': DateTime.now().toIso8601String(),
  });
}

// ─── CARE PLAN ────────────────────────────────────────────────────────────────

/// Returns care plan summary for the given patient.
Future<Map<String, dynamic>?> getCarePlanSummary(int patientProfileId) async {
  try {
    final response = await _db
        .from('care_plans')
        .select(
          'target_glucose_min, target_glucose_max, next_appointment, '
          'doctor_profile!care_plans_doctor_id_fkey(user_id, users(full_name))',
        )
        .eq('patient_id', patientProfileId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getCarePlanSummary error: $e');
    return null;
  }
}

// ─── IOB ──────────────────────────────────────────────────────────────────────

/// Returns the latest insulin on board value for this patient.
Future<double?> getLatestIOB(int patientProfileId) async {
  try {
    final response = await _db
        .from('insulin_on_board')
        .select('total_iob_units')
        .eq('patient_id', patientProfileId)
        .order('calculated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return double.tryParse(response['total_iob_units'].toString());
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getLatestIOB error: $e');
    return null;
  }
}

// ─── DEVICE BATTERY ───────────────────────────────────────────────────────────

/// Returns battery health string for the active device of this user.
Future<String?> getDeviceBattery(String userId) async {
  try {
    // Try active device first
    final activeDevice = await _db
        .from('devices')
        .select('battery_health')
        .eq('patient_id', userId)
        .eq('is_active', true)
        .order('last_sync_at', ascending: false)
        .maybeSingle();

    if (activeDevice != null && activeDevice['battery_health'] != null) {
      return activeDevice['battery_health'].toString();
    }

    // Fall back to most recent device
    final anyDevice = await _db
        .from('devices')
        .select('battery_health')
        .eq('patient_id', userId)
        .order('last_sync_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (anyDevice != null && anyDevice['battery_health'] != null) {
      return anyDevice['battery_health'].toString();
    }

    return null;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getDeviceBattery error: $e');
    return null;
  }
}
/// Inserts a new AI predicted glucose value from the BLE hardware.
/// [predictedValue] - The raw value predicted by the hardware's AI model.
/// Uses the Supabase Auth UUID as the `patient_id`.
Future<bool> insertAiPrediction(double predictedValue) async {
  try {
    final user = _db.auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print(
          '[SupabaseService] check failed: No user found for insertAiPrediction.',
        );
      }
      return false;
    }

    String riskLevel = 'IN_RANGE';
    if (predictedValue < 70) {
      riskLevel = 'LOW';
    } else if (predictedValue > 180) {
      riskLevel = 'HIGH';
    }

    final createdAt = DateTime.now().toUtc();
    final predictedFor = createdAt.add(const Duration(minutes: 5));

    await _db.from('ai_predictions').insert({
      'patient_id': user.id, // Supabase Auth UUID as requested
      'predicted_value': predictedValue,
      'horizon_minutes': 5,
      'confidence_score': 100.0,
      'risk_level': riskLevel,
      'model_version': '1',
      'created_at': createdAt.toIso8601String(),
      'predicted_for': predictedFor.toIso8601String(),
    });

    return true;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] insertAiPrediction error: $e');
    return false;
  }
}
