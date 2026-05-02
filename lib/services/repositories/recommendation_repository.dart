import 'base_repository.dart';

class RecommendationRepository extends BaseRepository {
  const RecommendationRepository(super.db);

  Future<List<Map<String, dynamic>>> getLatest({
    required int patientProfileId,
    int limit = 20,
  }) async {
    final response = await db
        .from('ai_recommendations')
        .select()
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> save({
    required int patientProfileId,
    required String category,
    required String message,
    String? predictionId,
  }) async {
    final row = {
      'patient_id': patientProfileId,
      'category': category,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      if (predictionId != null) 'prediction_id': predictionId,
    };
    return await db
        .from('ai_recommendations')
        .insert(row)
        .select()
        .single();
  }

  Future<void> markAsRead(String recommendationId) async {
    await db
        .from('ai_recommendations')
        .update({'is_read': true})
        .eq('id', recommendationId);
  }

  Future<void> delete(String recommendationId) async {
    await db
        .from('ai_recommendations')
        .delete()
        .eq('id', recommendationId);
  }

  Future<int> getUnreadCount(int patientProfileId) async {
    final response = await db
        .from('ai_recommendations')
        .select('id')
        .eq('patient_id', patientProfileId)
        .eq('is_read', false);
    return (response as List).length;
  }
}