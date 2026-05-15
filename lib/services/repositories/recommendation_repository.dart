import 'base_repository.dart';

class RecommendationRepository extends BaseRepository {
  const RecommendationRepository(super.db);

  Future<List<Map<String, dynamic>>> getLatest({
    required String patientProfileId, 
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
    required String patientProfileId, 
    required String category,
    required String message,
  }) async {
    final row = {
      'patient_id': patientProfileId, 
      'category': category,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    return await db.from('ai_recommendations').insert(row).select().single();
  }

  Future<void> deleteAllExcept({
    required String patientProfileId,
    required List<String> keepIds,
  }) async {
    await db
        .from('ai_recommendations')
        .delete()
        .eq('patient_id', patientProfileId)
        .not('id', 'in', keepIds);
  }

  Future<void> markAsRead(String recommendationId) async {
    await db
        .from('ai_recommendations')
        .update({'is_read': true})
        .eq('id', recommendationId);
  }

  Future<void> delete(String recommendationId) async {
    await db.from('ai_recommendations').delete().eq('id', recommendationId);
  }

  Future<int> getUnreadCount() async {
    final user = db.auth.currentUser;
    if (user == null) return 0;

    final response = await db
        .from('ai_recommendations')
        .select('id')
        .eq('patient_id', user.id)
        .eq('is_read', false);
    return (response as List).length;
  }
}