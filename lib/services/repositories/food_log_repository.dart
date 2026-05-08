import 'package:glucora_ai_companion/core/models/food_entry_model.dart';
import 'base_repository.dart';

class FoodLogRepository extends BaseRepository {
  const FoodLogRepository(super.db);

  Future<List<FoodEntry>> getTodayLogs(int patientProfileId) async {
    final startOfDay = DateTime.now().toLocal();
    final from =
        DateTime(startOfDay.year, startOfDay.month, startOfDay.day)
            .toUtc()
            .toIso8601String();

    final response = await db
        .from('food_logs')
        .select()
        .eq('patient_id', patientProfileId)
        .gte('logged_at', from)
        .order('logged_at', ascending: false);

    return (response as List).map((e) => FoodEntry.fromJson(e)).toList();
  }

  Future<void> insert({
    required int patientProfileId,
    required String name,
    required int calories,
    double? carbs,
    double? protein,
    double? fat,
    required String mealType,
  }) async {
    await db.from('food_logs').insert({
      'patient_id': patientProfileId,
      'name': name,
      'calories': calories,
      'carbs_g': ?carbs,
      'protein_g': ?protein,
      'fat_g': ?fat,
      'meal_type': mealType,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(int id) async {
    await db.from('food_logs').delete().eq('id', id);
  }
}