import 'base_repository.dart';

class IobRepository extends BaseRepository {
  const IobRepository(super.db);

  Future<Map<String, dynamic>?> getLatest(int patientProfileId) async {
    final response = await db
        .from('insulin_on_board')
        .select()
        .eq('patient_id', patientProfileId)
        .order('calculated_at', ascending: false)
        .limit(1);

    final data = response as List;
    return data.isNotEmpty ? data.first : null;
  }
}