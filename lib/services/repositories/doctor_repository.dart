import 'base_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
// Add this model at the top with the other models

class DoctorProfile {
  final String name;
  final String phone;
  final String email;
  final int age;
  final String address;
  final String profilePictureUrl;
  final String license;
  final String specialty;

  const DoctorProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.age,
    required this.address,
    required this.profilePictureUrl,
    required this.license,
    required this.specialty,
  });
}
class DoctorPatient {
  final int profileId;
  final String userId;
  final String name;
  final String? profilePictureUrl;
  final int glucoseValue;
  final String trend;
  final String lastReadingTime;
  final String status;

  const DoctorPatient({
    required this.profileId,
    required this.userId,
    required this.name,
    this.profilePictureUrl,
    required this.glucoseValue,
    required this.trend,
    required this.lastReadingTime,
    required this.status,
  });
  

  String get lastReading => '$glucoseValue mg/dL';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  static String calculateStatus(int glucose) {
    if (glucose < 70) return 'Low';
    if (glucose <= 180) return 'Normal';
    if (glucose <= 250) return 'High Risk';
    return 'Critical';
  }

  static String timeAgo(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}

/// Holds all data for the patient details screen, replacing the 7 parallel
/// Future.wait calls that used to live in the widget.
class PatientDetails {
  final Map<String, dynamic> profile;
  final Map<String, dynamic>? carePlan;
  final List<Map<String, dynamic>> glucoseReadings;
  final List<Map<String, dynamic>> insulinDoses;
  final List<Map<String, dynamic>> alerts;
  final Map<String, dynamic>? device;
  final Map<String, dynamic>? latestPrediction;
  final Map<String, dynamic>? latestIob;
  final String? profilePictureUrl;

  const PatientDetails({
    required this.profile,
    this.carePlan,
    required this.glucoseReadings,
    required this.insulinDoses,
    required this.alerts,
    this.device,
    this.latestPrediction,
    this.latestIob,
    this.profilePictureUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class DoctorRepository extends BaseRepository {
  const DoctorRepository(super.db);

  // ── existing: patient list ─────────────────────────────────────────────────

  Future<List<DoctorPatient>> getPatients(String doctorUserId) async {
    // Step 1 — get accepted connections with user data
    final connections = await db
        .from('doctor_patient_connections')
        .select(
          'patient_id, users!doctor_patient_connections_patient_id_fkey(full_name, profile_picture_url)',
        )
        .eq('doctor_id', doctorUserId)
        .eq('status', 'accepted') as List;

    if (connections.isEmpty) return [];

    // Step 2 — resolve patient profile IDs in one query
    final patientUserIds =
        connections.map((r) => r['patient_id'] as String).toList();

    final profiles = await db
        .from('patient_profile')
        .select('id, user_id')
        .inFilter('user_id', patientUserIds) as List;

    final Map<String, int> uuidToProfileId = {
      for (final p in profiles) p['user_id'] as String: p['id'] as int,
    };

    // Step 3 — fetch all readings in one query
    final profileIds = uuidToProfileId.values.toList();
    final readings = profileIds.isEmpty
        ? []
        : await db
              .from('glucose_readings')
              .select('patient_id, value_mg_dl, trend, recorded_at')
              .inFilter('patient_id', profileIds) as List;

    // Group readings by profile id
    final Map<int, List<dynamic>> readingsByPatient = {};
    for (final r in readings) {
      final pid = r['patient_id'] as int;
      readingsByPatient.putIfAbsent(pid, () => []).add(r);
    }

    return connections.map((row) {
      final userData = row['users'] as Map<String, dynamic>?;
      final patientUuid = row['patient_id'] as String;
      final profileId = uuidToProfileId[patientUuid] ?? 0;

      final patientReadings = List.from(readingsByPatient[profileId] ?? []);
      patientReadings.sort((a, b) => DateTime.parse(b['recorded_at'])
          .compareTo(DateTime.parse(a['recorded_at'])));

      final latest = patientReadings.isNotEmpty ? patientReadings.first : null;
      final glucoseValue =
          latest != null ? (latest['value_mg_dl'] as num).toInt() : 0;

      return DoctorPatient(
        profileId: profileId,
        userId: patientUuid,
        name: userData?['full_name'] ?? 'Unknown',
        profilePictureUrl: userData?['profile_picture_url'] as String?,
        glucoseValue: glucoseValue,
        trend: latest?['trend'] ?? 'stable',
        lastReadingTime: latest != null
            ? DoctorPatient.timeAgo(latest['recorded_at'])
            : 'No readings',
        status: DoctorPatient.calculateStatus(glucoseValue),
      );
    }).toList();
  }

  // ── new: full patient details ──────────────────────────────────────────────

  /// Fetches everything the PatientDetailsScreen needs in parallel.
  /// Mirrors the old Future.wait block that lived directly in the widget.
  Future<PatientDetails> getPatientDetails(int patientProfileId) async {
    // Profile (with joined user data for age + profile picture)
    final profile = await db
        .from('patient_profile')
        .select('*, users(full_name, age, profile_picture_url)')
        .eq('id', patientProfileId)
        .single();

    final userId = profile['user_id'] as String;
    final userData = profile['users'] as Map<String, dynamic>?;
    final profilePictureUrl = userData?['profile_picture_url'] as String?;

    // All other queries run in parallel
    final results = await Future.wait([
      // 0 — care plan
      db
          .from('care_plans')
          .select()
          .eq('patient_id', patientProfileId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      // 1 — glucose readings (ascending so charts render left→right)
      db
          .from('glucose_readings')
          .select()
          .eq('patient_id', patientProfileId)
          .order('recorded_at', ascending: true),
      // 2 — insulin doses
      db
          .from('insulin_doses')
          .select()
          .eq('patient_id', patientProfileId)
          .order('delivered_at', ascending: true),
      // 3 — recent alerts
      db
          .from('alerts')
          .select()
          .eq('patient_id', patientProfileId)
          .order('triggered_at', ascending: false)
          .limit(5),
      // 4 — active device (keyed by user UUID, not profile int id)
      db
          .from('devices')
          .select()
          .eq('patient_id', userId)
          .eq('is_active', true)
          .maybeSingle(),
      // 5 — latest AI prediction (also keyed by user UUID)
      db
          .from('ai_predictions')
          .select()
          .eq('patient_uuid', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      // 6 — latest IOB snapshot
      db
          .from('insulin_on_board')
          .select()
          .eq('patient_id', patientProfileId)
          .order('calculated_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    return PatientDetails(
      profile: profile,
      profilePictureUrl: profilePictureUrl,
      carePlan: results[0] as Map<String, dynamic>?,
      glucoseReadings:
          (results[1] as List).cast<Map<String, dynamic>>(),
      insulinDoses:
          (results[2] as List).cast<Map<String, dynamic>>(),
      alerts: (results[3] as List).cast<Map<String, dynamic>>(),
      device: results[4] as Map<String, dynamic>?,
      latestPrediction: results[5] as Map<String, dynamic>?,
      latestIob: results[6] as Map<String, dynamic>?,
    );
  }

  // ── new: remove patient connection ─────────────────────────────────────────

  /// Deletes the doctor↔patient connection row.
  /// The screen passes [patientProfileId] (the int PK); we look up the UUID
  /// first because the connection table stores UUIDs.
  Future<void> removePatient({
    required String doctorUserId,
    required int patientProfileId,
  }) async {
    // Resolve int profile id → user UUID
    final row = await db
        .from('patient_profile')
        .select('user_id')
        .eq('id', patientProfileId)
        .single();

    final patientUserId = row['user_id'] as String;

    await db
        .from('doctor_patient_connections')
        .delete()
        .eq('doctor_id', doctorUserId)
        .eq('patient_id', patientUserId);
  }

  // Add these methods inside DoctorRepository

  Future<DoctorProfile> getDoctorProfile(String userId) async {
    final response = await db
        .from('users')
        .select(
          'full_name, phone_no, email, age, address, profile_picture_url, '
          'doctor_profile(liscense_number, speciality)',
        )
        .eq('id', userId)
        .single();

    final rawUrl = response['profile_picture_url'] as String? ?? '';
    final baseUrl = rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;
    final profilePictureUrl = baseUrl.isNotEmpty
        ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
        : '';

    final dynamic profileData = response['doctor_profile'];
    String license = 'Not Set';
    String specialty = 'General Practitioner';
    if (profileData != null) {
      final profile = profileData is List ? profileData.first : profileData;
      license = profile['liscense_number'] ?? 'Not Set';
      specialty = profile['speciality'] ?? 'General Practitioner';
    }

    return DoctorProfile(
      name: response['full_name'] ?? 'Unknown Doctor',
      phone: response['phone_no'] ?? 'No Phone',
      email: response['email'] ?? '',
      age: (response['age'] as num?)?.toInt() ?? 0,
      address: response['address'] ?? 'No Address Set',
      profilePictureUrl: profilePictureUrl,
      license: license,
      specialty: specialty,
    );
  }

  Future<void> updateDoctorProfile({
    required String userId,
    required String fullName,
    required String phoneNo,
    required int age,
    required String address,
    required String specialty,
    required String licenseNumber,
  }) async {
    await Future.wait([
      db.from('users').update({
        'full_name': fullName,
        'phone_no': phoneNo,
        'age': age,
        'address': address,
      }).eq('id', userId),
      db.from('doctor_profile').update({
        'speciality': specialty,
        'liscense_number': licenseNumber,
      }).eq('user_id', userId),
    ]);
  }

  RealtimeChannel subscribeToDoctorProfileChanges({
    required String userId,
    required VoidCallback onChanged,
  }) {
    return db
        .channel('doctor_profile_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) => onChanged(),
        )
        .subscribe();
  }
}