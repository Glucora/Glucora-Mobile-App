// lib\services\repositories\patient_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'base_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class PatientProfile {
  final String name;
  final String email;
  final String phone;
  final int age;
  final String height;
  final String weight;
  final String profilePictureUrl;

  const PatientProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.height,
    required this.weight,
    required this.profilePictureUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class PatientRepository extends BaseRepository {
  const PatientRepository(super.db);

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<PatientProfile> getProfile(String userId) =>
      safeQuery(() async {
        // Fetch both tables in parallel
        final results = await Future.wait([
          db
              .from('users')
              .select('full_name, email, phone_no, age, profile_picture_url')
              .eq('id', userId)
              .maybeSingle(),
          db
              .from('patient_profile')
              .select('height_cm, weight_kg')
              .eq('user_id', userId)
              .maybeSingle(),
        ]);

        var userData = results[0];
        var patientData = results[1];

        // Auto-create missing rows — same logic that was in the controller
        userData ??= await db
            .from('users')
            .insert({
              'id': userId,
              'email': '',
              'full_name': 'New User',
            })
            .select()
            .single();

        patientData ??= await db
            .from('patient_profile')
            .insert({'user_id': userId, 'height_cm': 0, 'weight_kg': 0})
            .select()
            .single();

        final rawUrl =
            userData['profile_picture_url'] as String? ?? '';
        final baseUrl =
            rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;
        final profilePictureUrl = baseUrl.isNotEmpty
            ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
            : '';

        return PatientProfile(
          name: userData['full_name'] ?? 'No Name',
          email: userData['email'] ?? '',
          phone: userData['phone_no'] ?? '',
          age: (userData['age'] as num?)?.toInt() ?? 0,
          height: '${patientData['height_cm'] ?? 0} cm',
          weight: '${patientData['weight_kg'] ?? 0} kg',
          profilePictureUrl: profilePictureUrl,
        );
      });

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required int age,
    required double heightCm,
    required double weightKg,
  }) =>
      safeQuery(() async {
        await Future.wait([
          db.from('users').update({
            'full_name': fullName,
            'email': email,
            'phone_no': phone,
            'age': age,
          }).eq('id', userId),
          db.from('patient_profile').update({
            'height_cm': heightCm,
            'weight_kg': weightKg,
          }).eq('user_id', userId),
        ]);
      });

  // ── Role switch ───────────────────────────────────────────────────────────

  Future<void> switchRole(String userId, String role) =>
      safeQuery(() async {
        await db
            .from('users')
            .update({'role': role})
            .eq('id', userId);
      });

  // ── Realtime ──────────────────────────────────────────────────────────────

  RealtimeChannel subscribeToProfileChanges({
    required String userId,
    required VoidCallback onChanged,
  }) {
    return db
        .channel('patient_profile_$userId')
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