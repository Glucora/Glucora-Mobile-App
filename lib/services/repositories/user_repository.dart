import '../../core/models/admin_model.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  const UserRepository(super.db);

  Future<List<AdminUser>> getAll() async {
    final response = await db
        .from('users')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List).map((u) => AdminUser.fromMap(u)).toList();
  }

  Future<void> update(AdminUser user) async {
    await db.from('users').update(user.toMap()).eq('id', user.id);
  }

  Future<void> toggleStatus(String userId, bool isActive) async {
    await db
        .from('users')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  Future<int> getCount() async {
    final response = await db.from('users').select('id');
    return (response as List).length;
  }
  Future<void> deleteUser(String userId, String role) async {
    if (role == 'doctor') {
      try { await db.from('care_plans').delete().eq('doctor_id', userId); } catch (_) {}
      try { await db.from('doctor_patient_connections').delete().eq('doctor_id', userId); } catch (_) {}
      try { await db.from('doctor_profile').delete().eq('user_id', userId); } catch (_) {}

    } else if (role == 'patient') {
      try {
        final profile = await db
            .from('patient_profile')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (profile != null) {
          try { await db.from('glucose_readings').delete().eq('patient_id', profile['id']); } catch (_) {}
          try { await db.from('insulin_doses').delete().eq('patient_id', profile['id']); } catch (_) {}
        }
      } catch (_) {}
      try { await db.from('patient_profile').delete().eq('user_id', userId); } catch (_) {}
      try { await db.from('guardian_patient_connections').delete().eq('patient_id', userId); } catch (_) {}
      try { await db.from('doctor_patient_connections').delete().eq('patient_id', userId); } catch (_) {}
      try { await db.from('patient_locations').delete().eq('patient_id', userId); } catch (_) {}
      try { await db.from('devices').delete().eq('patient_id', userId); } catch (_) {}

    } else if (role == 'guardian') {
      try { await db.from('guardian_patient_connections').delete().eq('guardian_id', userId); } catch (_) {}
    }

    await db.rpc('delete_user_by_id', params: {'user_id': userId});
  }

  Future<void> updateUserRoleAndStatus(
      String userId, String role, bool isActive) async {
    await db
        .from('users')
        .update({'role': role, 'is_active': isActive})
        .eq('id', userId);
  }
}
