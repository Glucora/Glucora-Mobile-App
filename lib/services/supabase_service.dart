import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

final _db = Supabase.instance.client;

// ─── PATIENT PROFILE ──────────────────────────────────────────────────────────

/// Returns patient_profiles.id for the given Supabase Auth user id.
/// This is DIFFERENT from auth user id — always call this first.
Future<String?> getPatientProfileId(String authUserId) async {
  try {
    final row = await _db
        .from('patient_profiles')
        .select('id')
        .eq('user_id', authUserId)
        .maybeSingle();
    return row?['id'] as String?;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getPatientProfileId error: $e');
    return null;
  }
}

// ─── GLUCOSE ──────────────────────────────────────────────────────────────────

/// Returns the most recent glucose reading row for this patient.
Future<Map<String, dynamic>?> getLatestGlucoseReading(
    String patientProfileId) async {
  try {
    return await _db
        .from('glucose_readings')
        .select()
        .eq('patient_id', patientProfileId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getLatestGlucoseReading error: $e');
    return null;
  }
}

// ─── AI PREDICTIONS ───────────────────────────────────────────────────────────

/// Returns the most recent LSTM prediction row for this patient.
Future<Map<String, dynamic>?> getLatestPrediction(
    String patientProfileId) async {
  try {
    return await _db
        .from('ai_predictions')
        .select()
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] getLatestPrediction error: $e');
    return null;
  }
}

// ─── AI RECOMMENDATIONS ───────────────────────────────────────────────────────

/// Save a single recommendation row.
/// [patientProfileId] = patient_profiles.id (NOT auth user id).
/// Returns the saved row including its generated uuid id.
Future<Map<String, dynamic>?> saveRecommendation({
  required String patientProfileId,
  required String category,
  required String message,
  String? predictionId, // optional FK to ai_predictions.id
}) async {
  try {
    final row = <String, dynamic>{
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

    if (kDebugMode) print('[SupabaseService] Saved recommendation: ${response['id']}');
    return response;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] saveRecommendation error: $e');
    return null;
  }
}

/// Fetch saved recommendations for this patient, newest first.
Future<List<Map<String, dynamic>>> getSavedRecommendations({
  required String patientProfileId,
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
    if (kDebugMode) print('[SupabaseService] getSavedRecommendations error: $e');
    return [];
  }
}

/// Mark a recommendation as read by its uuid id.
Future<bool> markRecommendationAsRead(String recommendationId) async {
  try {
    await _db
        .from('ai_recommendations')
        .update({'is_read': true})
        .eq('id', recommendationId);
    return true;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] markAsRead error: $e');
    return false;
  }
}

/// Delete a recommendation by its uuid id.
Future<bool> deleteRecommendation(String recommendationId) async {
  try {
    await _db
        .from('ai_recommendations')
        .delete()
        .eq('id', recommendationId);
    return true;
  } catch (e) {
    if (kDebugMode) print('[SupabaseService] deleteRecommendation error: $e');
    return false;
  }
}

/// Count unread recommendations for this patient.
Future<int> getUnreadCount(String patientProfileId) async {
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