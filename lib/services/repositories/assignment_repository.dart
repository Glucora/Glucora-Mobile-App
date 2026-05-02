import '../../core/models/admin_model.dart';
import 'base_repository.dart';

class AssignmentRepository extends BaseRepository {
  const AssignmentRepository(super.db);

  /// Fixes the N+1 problem — fetches all connections then resolves
  /// all names in 2 queries instead of one per connection
  Future<List<DoctorPatientAssignment>> getAll() async {
    final connections = await db
        .from('doctor_patient_connections')
        .select('doctor_id, patient_id')
        .eq('status', 'accepted');

    if ((connections as List).isEmpty) return [];

    // Collect all unique user IDs
    final allIds = <String>{};
    for (final c in connections) {
      allIds.add(c['doctor_id'] as String);
      allIds.add(c['patient_id'] as String);
    }

    // Single query for all names
    final users = await db
        .from('users')
        .select('id, full_name')
        .inFilter('id', allIds.toList());

    final nameMap = {
      for (final u in users as List)
        u['id'] as String: u['full_name'] as String? ?? 'Unknown',
    };

    return connections.map((c) {
      final doctorId = c['doctor_id'] as String;
      final patientId = c['patient_id'] as String;
      return DoctorPatientAssignment(
        doctorId: doctorId,
        doctorName: nameMap[doctorId] ?? 'Unknown Doctor',
        patientId: patientId,
        patientName: nameMap[patientId] ?? 'Unknown Patient',
      );
    }).toList();
  }

  Future<bool> assign(String doctorId, String patientId) async {
    final existing = await db
        .from('doctor_patient_connections')
        .select()
        .eq('doctor_id', doctorId)
        .eq('patient_id', patientId)
        .maybeSingle();

    if (existing != null) return false;

    await db.from('doctor_patient_connections').insert({
      'doctor_id': doctorId,
      'patient_id': patientId,
      'status': 'accepted',
    });
    return true;
  }

  Future<void> remove(String doctorId, String patientId) async {
    await db
        .from('doctor_patient_connections')
        .delete()
        .eq('doctor_id', doctorId)
        .eq('patient_id', patientId);
  }
}