import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// ConnectionPerson  (Value Object)
// ─────────────────────────────────────────────────────────────
@immutable
class ConnectionPerson {
  final String connectionId;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Guardian' | 'Doctor'
  final String relationship; // only for guardians

  const ConnectionPerson({
    required this.connectionId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.relationship = '',
  });

  String get initials => name
      .trim()
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0])
      .take(2)
      .join();

  String get tableName => role == 'Guardian'
      ? 'guardian_patient_connections'
      : 'doctor_patient_connections';
}

// ─────────────────────────────────────────────────────────────
// ConnectionsController  (ChangeNotifier – Controller layer)
// ─────────────────────────────────────────────────────────────
class ConnectionsController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool isLoading = true;
  bool globalLocationSharing = true;
  int? _patientLocationRowId;

  final Map<String, bool> sharingMap = {};
  List<ConnectionPerson> guardians = [];
  List<ConnectionPerson> doctors = [];

  // ── Lifecycle ────────────────────────────────────────────
  Future<void> loadConnections() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final userId = user.id;

      // Location row
      var locationRow = await _supabase
          .from('patient_locations')
          .select('id, sharing_enabled')
          .eq('patient_id', userId)
          .maybeSingle();

      locationRow ??= await _supabase
          .from('patient_locations')
          .insert({'patient_id': userId, 'sharing_enabled': true})
          .select('id, sharing_enabled')
          .single();

      _patientLocationRowId = locationRow['id'] as int;
      globalLocationSharing = locationRow['sharing_enabled'] ?? true;

      // Guardian connections
      final guardianRows = await _supabase
          .from('guardian_patient_connections')
          .select(
            'id, guardian_id, relationship, is_sharing, users!guardian_id(full_name, email, phone_no)',
          )
          .eq('patient_id', userId)
          .eq('status', 'accepted');

      // Doctor connections
      final doctorRows = await _supabase
          .from('doctor_patient_connections')
          .select(
            'id, doctor_id, is_sharing, users!doctor_id(full_name, email, phone_no)',
          )
          .eq('patient_id', userId)
          .eq('status', 'accepted');

      guardians = _parseConnections(guardianRows as List, 'Guardian');
      doctors   = _parseConnections(doctorRows   as List, 'Doctor');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('ConnectionsController error: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  List<ConnectionPerson> _parseConnections(
      List<dynamic> rows, String role) {
    final result = <ConnectionPerson>[];
    for (final row in rows) {
      final userInfo = row['users'] as Map<String, dynamic>?;
      final id = row['id'].toString();
      final person = ConnectionPerson(
        connectionId: id,
        name: userInfo?['full_name'] ?? 'Unknown',
        email: userInfo?['email'] ?? '',
        phone: userInfo?['phone_no'] ?? '',
        role: role,
        relationship: row['relationship'] ?? '',
      );
      result.add(person);
      sharingMap[id] = row['is_sharing'] ?? true;
    }
    return result;
  }

  // ── Global toggle ─────────────────────────────────────────
  Future<void> toggleGlobalSharing(bool value) async {
    final previous = globalLocationSharing;
    globalLocationSharing = value;
    notifyListeners();

    try {
      await _supabase
          .from('patient_locations')
          .update({'sharing_enabled': value})
          .eq('id', _patientLocationRowId!);
    } catch (_) {
      globalLocationSharing = previous;
      notifyListeners();
      rethrow;
    }
  }

  // ── Per-person toggle ─────────────────────────────────────
  Future<void> togglePersonSharing(
      ConnectionPerson person, bool value) async {
    final id = person.connectionId;
    final previous = sharingMap[id];
    sharingMap[id] = value;
    notifyListeners();

    try {
      await _supabase
          .from(person.tableName)
          .update({'is_sharing': value})
          .eq('id', int.parse(id));
    } catch (_) {
      sharingMap[id] = previous ?? true;
      notifyListeners();
      rethrow;
    }
  }

  // ── Remove connection ─────────────────────────────────────
  Future<void> removeConnection(ConnectionPerson person) async {
    final id = int.parse(person.connectionId);
    await _supabase.from(person.tableName).delete().eq('id', id);

    if (person.role == 'Guardian') {
      guardians.removeWhere((g) => g.connectionId == person.connectionId);
    } else {
      doctors.removeWhere((d) => d.connectionId == person.connectionId);
    }
    sharingMap.remove(person.connectionId);
    notifyListeners();
  }

  bool effectivelySharing(ConnectionPerson person) =>
      (sharingMap[person.connectionId] ?? true) && globalLocationSharing;
}
