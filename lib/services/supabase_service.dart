import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
    if (kDebugMode) {
      print('[SupabaseService] getPatientProfileId error: $e');
    }
    return null;
  }
}

// ─── GLUCOSE ──────────────────────────────────────────────────────────────────

/// Returns the most recent glucose reading row for this patient.
Future<Map<String, dynamic>?> getLatestGlucoseReading(int patientProfileId) async {
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
    if (kDebugMode) print('[SupabaseService] getLatestGlucoseReading error: $e');
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
    if (kDebugMode) {
      print('[SupabaseService] getLatestPrediction error: $e');
    }
    return null;
  }
}

// ─── AI RECOMMENDATIONS ───────────────────────────────────────────────────────

/// Save a single recommendation row.
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

    if (predictionId != null) {
      row['prediction_id'] = predictionId;
    }

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
    if (kDebugMode) {
      print('[SupabaseService] saveRecommendation error: $e');
    }
    return null;
  }
}

/// Fetch saved recommendations for this patient.
Future<List<Map<String, dynamic>>> getSavedRecommendations({
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
      print('[SupabaseService] getSavedRecommendations error: $e');
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
    await _db
        .from('ai_recommendations')
        .delete()
        .eq('id', recommendationId);

    return true;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseService] deleteRecommendation error: $e');
    }
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
    if (kDebugMode) {
      print('[SupabaseService] getUnreadCount error: $e');
    }
    return 0;
  }
}