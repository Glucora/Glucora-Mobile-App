import '../../core/models/glucose_log_model.dart';
import 'base_repository.dart';

class GlucoseRepository extends BaseRepository {
  const GlucoseRepository(super.db);

  Future<int?> getPatientProfileId(String authUserId) async {
    final row = await db
        .from('patient_profile')
        .select('id')
        .eq('user_id', authUserId)
        .maybeSingle();
    return row?['id'] as int?;
  }

  Future<Map<String, dynamic>?> getLatestReading(int patientProfileId) async {
    return await db
        .from('glucose_readings')
        .select('id, patient_id, value_mg_dl, recorded_at, trend, source')
        .eq('patient_id', patientProfileId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<List<GlucoseLog>> fetchLogs(int patientProfileId) async {
    final response = await db
        .from('glucose_readings')
        .select()
        .eq('patient_id', patientProfileId)
        .order('recorded_at', ascending: false);
    return (response as List).map((e) => GlucoseLog.fromJson(e)).toList();
  }

  Future<void> insertLog(
    int patientProfileId,
    double value,
    String? notes,
    String mealTime,
  ) async {
    await db.from('glucose_readings').insert({
      'value_mg_dl': value,
      'source': 'manual',
      'trend': 'stable',
      'patient_id': patientProfileId,
      'is_predicted': false,
      'meal_time': mealTime,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }
}