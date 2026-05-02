import 'base_repository.dart';

class PredictionRepository extends BaseRepository {
  const PredictionRepository(super.db);

  Future<Map<String, dynamic>?> getLatest(int patientProfileId) async {
    return await db
        .from('ai_predictions')
        .select()
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<bool> insert(double predictedValue) async {
    final user = db.auth.currentUser;
    if (user == null) return false;

    String riskLevel = 'IN_RANGE';
    if (predictedValue < 70) riskLevel = 'LOW';
    if (predictedValue > 180) riskLevel = 'HIGH';

    final createdAt = DateTime.now().toUtc();
    final predictedFor = createdAt.add(const Duration(minutes: 5));

    await db.from('ai_predictions').insert({
      'patient_id': user.id,
      'predicted_value': predictedValue,
      'horizon_minutes': 5,
      'confidence_score': 100.0,
      'risk_level': riskLevel,
      'model_version': '1',
      'created_at': createdAt.toIso8601String(),
      'predicted_for': predictedFor.toIso8601String(),
    });

    return true;
  }
}