import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// PatientProfileState  (Value Object / Snapshot)
// ─────────────────────────────────────────────────────────────
@immutable
class PatientProfileState {
  final String name;
  final int age;
  final String height;
  final String weight;
  final String phone;
  final String email;
  final String profilePictureUrl;
  final bool isLoading;

  const PatientProfileState({
    this.name = '',
    this.age = 0,
    this.height = '',
    this.weight = '',
    this.phone = '',
    this.email = '',
    this.profilePictureUrl = '',
    this.isLoading = true,
  });

  PatientProfileState copyWith({
    String? name,
    int? age,
    String? height,
    String? weight,
    String? phone,
    String? email,
    String? profilePictureUrl,
    bool? isLoading,
  }) {
    return PatientProfileState(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PatientProfileController  (ChangeNotifier – Controller layer)
//
// Responsibilities:
//   • Fetches and caches profile data from Supabase.
//   • Subscribes to real-time changes.
//   • Exposes a single [state] snapshot to the UI.
//   • Handles role-switch to guardian.
//
// The UI layer (PatientProfileTab) never calls Supabase directly.
// ─────────────────────────────────────────────────────────────
class PatientProfileController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  PatientProfileState _state = const PatientProfileState();
  PatientProfileState get state => _state;

  // Bumped on every successful load so widgets using ValueKey can fully
  // rebuild (e.g. to bust image cache).
  int _reloadKey = 0;
  int get reloadKey => _reloadKey;

  RealtimeChannel? _profileChannel;

  // ── Lifecycle ────────────────────────────────────────────
  void init() {
    loadProfile();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────
  Future<void> loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      var userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      userData ??= await _supabase
          .from('users')
          .insert({
            'id': user.id,
            'email': user.email,
            'full_name': 'New User',
          })
          .select()
          .single();

      var patientData = await _supabase
          .from('patient_profile')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      patientData ??= await _supabase
          .from('patient_profile')
          .insert({'user_id': user.id, 'height_cm': 0, 'weight_kg': 0})
          .select()
          .single();

      final rawUrl = userData?['profile_picture_url'] as String? ?? '';
      final baseUrl =
          rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;
      final cachedUrl = baseUrl.isNotEmpty
          ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
          : '';

      _state = PatientProfileState(
        name: userData?['full_name'] ?? 'No Name',
        phone: userData?['phone_no'] ?? '',
        email: userData?['email'] ?? '',
        age: (userData?['age'] ?? 0).toInt(),
        height: '${patientData?['height_cm'] ?? 0} cm',
        weight: '${patientData?['weight_kg'] ?? 0} kg',
        profilePictureUrl: cachedUrl,
        isLoading: false,
      );
      _reloadKey++;
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // ── Real-time subscription ────────────────────────────────
  void _subscribeToRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _profileChannel = _supabase
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
          callback: (_) => loadProfile(),
        )
        .subscribe();
  }

  // ── Save edits ────────────────────────────────────────────
  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required int age,
    required double heightCm,
    required double weightKg,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.auth.updateUser(
      UserAttributes(
        email: email != user.email ? email : null,
        data: {'full_name': name, 'phone': phone},
      ),
    );

    await _supabase
        .from('users')
        .update({
          'full_name': name,
          'email': email,
          'phone_no': phone,
          'age': age,
        })
        .eq('id', user.id);

    await _supabase
        .from('patient_profile')
        .update({'weight_kg': weightKg, 'height_cm': heightCm})
        .eq('user_id', user.id);

    await loadProfile();
  }

  // ── Role switch ───────────────────────────────────────────
  Future<void> switchToGuardian() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('users')
        .update({'role': 'guardian'})
        .eq('id', userId);
  }
}
