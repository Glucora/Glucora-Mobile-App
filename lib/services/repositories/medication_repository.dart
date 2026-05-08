import 'package:glucora_ai_companion/core/models/medication_model.dart';
import 'base_repository.dart';

class MedicationRepository extends BaseRepository {
  const MedicationRepository(super.db);

  Future<List<Medication>> getAll(int patientProfileId) async {
    final response = await db
        .from('medications')
        .select('*, medication_reminder(*)')
        .eq('patient_id', patientProfileId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Medication.fromJson(e)).toList();
  }

  Future<int> insert({
    required int patientProfileId,
    required String name,
    String? notes,
    int? frequency,
  }) async {
    final response = await db
        .from('medications')
        .insert({
          'patient_id': patientProfileId,
          'name': name,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'frequency': ?frequency,
          'is_active': true,
        })
        .select()
        .single();
    return response['id'] as int;
  }

  Future<void> toggle(int medId, bool isActive) async {
    await db
        .from('medications')
        .update({'is_active': isActive})
        .eq('id', medId);
  }

  Future<void> delete(int medId) async {
    await db
        .from('medications')
        .delete()
        .eq('id', medId);
  }

  // ── Reminders ──────────────────────────────────────────────────────────────

  Future<int> insertReminder({
    required int medId,
    required String remindAt,
  }) async {
    final response = await db
        .from('medication_reminder')
        .insert({
          'medication_id': medId,
          'remind_at': remindAt,
          'is_active': true,
        })
        .select()
        .single();
    return response['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getReminders(int medId) async {
    final response = await db
        .from('medication_reminder')
        .select('id')
        .eq('medication_id', medId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteReminders(int medId) async {
    await db
        .from('medication_reminder')
        .delete()
        .eq('medication_id', medId);
  }
}