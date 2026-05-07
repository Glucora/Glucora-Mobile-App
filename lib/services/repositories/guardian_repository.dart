// lib\services\repositories\guardian_repository.dart
import 'package:glucora_ai_companion/core/models/guardian_patient_model.dart';
import 'base_repository.dart';

class GuardianRepository extends BaseRepository {
  const GuardianRepository(super.db);

  Future<List<GuardianPatient>> getPatients(String guardianUserId) async {
    // Step 1 — connections with user info
    final connections = await db
        .from('guardian_patient_connections')
        .select('''
          patient_id,
          relationship,
          users!patient_id(full_name, age, phone_no, profile_picture_url)
        ''')
        .eq('guardian_id', guardianUserId)
        .eq('status', 'accepted') as List;

    if (connections.isEmpty) return [];

    // Step 2 — resolve profile IDs
    final patientUserIds =
        connections.map((r) => r['patient_id'] as String).toList();

    final profiles = await db
        .from('patient_profile')
        .select('id, user_id')
        .inFilter('user_id', patientUserIds) as List;

    final Map<String, int> uuidToProfileId = {
      for (final p in profiles) p['user_id'] as String: p['id'] as int,
    };

    final patientProfileIds = uuidToProfileId.values.toList();

    // Step 3 — all readings in one query
    final readings = patientProfileIds.isEmpty
        ? []
        : await db
              .from('glucose_readings')
              .select('patient_id, value_mg_dl, trend, recorded_at')
              .inFilter('patient_id', patientProfileIds)
              .order('recorded_at', ascending: false) as List;

    // Step 4 — today's doses
    final startOfDay = DateTime.now()
        .toUtc()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

    final doses = patientProfileIds.isEmpty
        ? []
        : await db
              .from('insulin_doses')
              .select('patient_id, delivery_method, delivered_at')
              .inFilter('patient_id', patientProfileIds)
              .gte('delivered_at', startOfDay.toIso8601String()) as List;

    // Step 5 — device status
    final devices = await db
        .from('devices')
        .select('patient_id, device_type, is_active')
        .inFilter('patient_id', patientUserIds) as List;

    // Build device status map
    final Map<String, Map<String, bool>> deviceStatus = {};
    for (final d in devices) {
      final uuid = d['patient_id'] as String;
      final type = (d['device_type'] as String? ?? '').toLowerCase();
      final active = d['is_active'] as bool? ?? false;
      deviceStatus.putIfAbsent(uuid, () => {'sensor': false, 'pump': false});
      if ((type.contains('cgm') || type.contains('sensor')) && active) {
        deviceStatus[uuid]!['sensor'] = true;
      }
      if (type.contains('pump') && active) {
        deviceStatus[uuid]!['pump'] = true;
      }
    }

    // Group readings and doses by profile id
    final Map<int, List<dynamic>> readingsByPatient = {};
    for (final r in readings) {
      final pid = r['patient_id'] as int;
      readingsByPatient.putIfAbsent(pid, () => []).add(r);
    }

    final Map<int, List<dynamic>> dosesByPatient = {};
    for (final d in doses) {
      final pid = d['patient_id'] as int;
      dosesByPatient.putIfAbsent(pid, () => []).add(d);
    }

    final List<GuardianPatient> result = [];

    for (final row in connections) {
      final user = row['users'] as Map<String, dynamic>?;
      final patientUuid = row['patient_id'] as String;
      final profileId = uuidToProfileId[patientUuid];
      if (profileId == null) continue;

      final patientReadings = readingsByPatient[profileId] ?? [];
      final latestReading =
          patientReadings.isNotEmpty ? patientReadings.first : null;
      final glucose =
          (latestReading?['value_mg_dl'] as num?)?.toInt() ?? 0;
      final trend = latestReading?['trend'] as String? ?? 'stable';
      final lastSeen = latestReading != null
          ? _timeAgo(latestReading['recorded_at'] as String)
          : 'No readings';

      final patientDoses = dosesByPatient[profileId] ?? [];
      final allAutomatic = patientDoses.isNotEmpty &&
          patientDoses.every((d) => d['delivery_method'] == 'Pump');

      final ds = deviceStatus[patientUuid];

      result.add(GuardianPatient(
        profileId: profileId,
        id: patientUuid,
        patientId: patientUuid,
        name: user?['full_name'] as String? ?? 'Unknown',
        age: (user?['age'] as num?)?.toInt() ?? 0,
        relationship: row['relationship'] as String? ?? 'Guardian',
        glucoseValue: glucose,
        glucoseTrend: trend,
        sensorConnected: ds?['sensor'] ?? false,
        pumpActive: ds?['pump'] ?? false,
        dosesToday: patientDoses.length,
        allDosesAutomatic: allAutomatic,
        lastSeenTime: lastSeen,
        phoneNumber: user?['phone_no'] as String? ?? '',
        profilePictureUrl: user?['profile_picture_url'] as String?,
      ));
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getInsulinDosesToday(
      int patientProfileId) async {
    final startOfDay = DateTime.now()
        .toUtc()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await db
        .from('insulin_doses')
        .select('units')
        .eq('patient_id', patientProfileId)
        .gte('delivered_at', startOfDay.toIso8601String())
        .lte('delivered_at', endOfDay.toIso8601String());

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getGlucoseReadingsToday(
      int patientProfileId) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await db
        .from('glucose_readings')
        .select('value_mg_dl, recorded_at')
        .eq('patient_id', patientProfileId)
        .gte('recorded_at', startOfDay.toIso8601String())
        .lte('recorded_at', endOfDay.toIso8601String())
        .order('recorded_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getCarePlan(int patientProfileId) async {
    final response = await db
        .from('care_plans')
        .select('''
          target_glucose_min,
          target_glucose_max,
          insulin_type,
          max_auto_dose_units,
          aid_mode_enabled,
          notes,
          next_appointment,
          updated_at,
          doctor_profile!care_plans_doctor_id_fkey(
            user_id,
            users(full_name)
          )
        ''')
        .eq('patient_id', patientProfileId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  static String _timeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (_) {
      return 'Unknown';
    }
  }
}