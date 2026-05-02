import '../../core/models/admin_model.dart';
import 'base_repository.dart';

class DeviceRepository extends BaseRepository {
  const DeviceRepository(super.db);

  /// Fixes the N+1 problem — fetches all devices + all users in 2 queries
  Future<List<AdminDevice>> getAll() async {
    final devices = await db
        .from('devices')
        .select('*')
        .order('created_at', ascending: false);

    if ((devices as List).isEmpty) return [];

    // Collect all non-null patient IDs in one go
    final patientIds = devices
        .where((d) => d['patient_id'] != null)
        .map((d) => d['patient_id'] as String)
        .toSet()
        .toList();

    // Single query for all users instead of one per device
    Map<String, String> userNames = {};
    if (patientIds.isNotEmpty) {
      final users = await db
          .from('users')
          .select('id, full_name')
          .inFilter('id', patientIds);

      userNames = {
        for (final u in users as List)
          u['id'] as String: u['full_name'] as String? ?? 'Unknown',
      };
    }

    return devices.map((d) {
      final name = d['patient_id'] != null
          ? userNames[d['patient_id']] ?? 'Unassigned'
          : 'Unassigned';
      return AdminDevice.fromMap(d, assignedUserName: name);
    }).toList();
  }

  Future<void> assign(String deviceId, String patientId) async {
    await db
        .from('devices')
        .update({'patient_id': patientId, 'is_active': true})
        .eq('id', deviceId);
  }

  Future<void> unassign(String deviceId) async {
    await db
        .from('devices')
        .update({'patient_id': null, 'is_active': false})
        .eq('id', deviceId);
  }

  Future<void> add(AdminDevice device) async {
    await db.from('devices').insert(device.toMap());
  }

  Future<void> update(AdminDevice device) async {
    await db.from('devices').update(device.toMap()).eq('id', device.id);
  }

  Future<void> delete(String deviceId) async {
    await db.from('devices').delete().eq('id', deviceId);
  }

  Future<int> getCount() async {
    final response = await db.from('devices').select('id');
    return (response as List).length;
  }

  Future<int> getActiveCount() async {
    final response = await db
        .from('devices')
        .select('id')
        .eq('is_active', true);
    return (response as List).length;
  }

  Future<int> getInactiveCount() async {
    final response = await db
        .from('devices')
        .select('id')
        .eq('is_active', false);
    return (response as List).length;
  }

  Future<String?> getBattery(String userId) async {
    final active = await db
        .from('devices')
        .select('battery_health')
        .eq('patient_id', userId)
        .eq('is_active', true)
        .order('last_sync_at', ascending: false)
        .maybeSingle();

    if (active?['battery_health'] != null) {
      return active!['battery_health'].toString();
    }

    final any = await db
        .from('devices')
        .select('battery_health')
        .eq('patient_id', userId)
        .order('last_sync_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return any?['battery_health']?.toString();
  }
}