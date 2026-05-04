import '../../core/models/care_plan_model.dart';
import 'base_repository.dart';

class CarePlanRepository extends BaseRepository {
  const CarePlanRepository(super.db);

  Future<Map<String, dynamic>?> getRaw(int patientProfileId) async {
    return await db
        .from('care_plans')
        .select('*, doctor_profile(user_id, users(full_name))')
        .eq('patient_id', patientProfileId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  CarePlan parseCarePlan(Map<String, dynamic> response) {
    List<BasalSegment> basalProgram = [];
    final rawBasal = response['basal_program'];
    if (rawBasal != null && rawBasal is List) {
      basalProgram = rawBasal
          .map((seg) => BasalSegment(
                startHour: (seg['start_hour'] as num).toInt(),
                endHour: (seg['end_hour'] as num).toInt(),
                rate: (seg['rate'] as num).toDouble(),
              ))
          .toList();
    }
    if (basalProgram.isEmpty) {
      basalProgram = [BasalSegment(startHour: 0, endHour: 24, rate: 0.9)];
    }

    return CarePlan(
      targetGlucoseMin: response['target_glucose_min'] != null
          ? (response['target_glucose_min'] as num).toInt()
          : 70,
      targetGlucoseMax: response['target_glucose_max'] != null
          ? (response['target_glucose_max'] as num).toInt()
          : 180,
      insulinType: response['insulin_type'] ?? 'NovoLog (Fast-Acting)',
      basalProgram: basalProgram,
      insulinToCarbRatio: response['carb_ratio'] != null
          ? (response['carb_ratio'] as num).toDouble()
          : 12,
      sensitivityFactor: response['insulin_sensitivity_factor'] != null
          ? double.tryParse(
                  response['insulin_sensitivity_factor'].toString()) ??
              45
          : 45,
      maxAutoBolus: response['max_auto_dose_units'] != null
          ? (response['max_auto_dose_units'] as num).toDouble()
          : 4.0,
      doctorNotes: response['notes'] ?? '',
      nextAppointment: response['next_appointment'] != null
          ? DateTime.tryParse(response['next_appointment'])
          : null,
    );
  }
}