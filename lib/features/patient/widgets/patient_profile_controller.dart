import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/services/repositories/patient_repository.dart';

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
  final PatientRepository _repo;
  PatientProfileController(this._repo);

  PatientProfileState _state = const PatientProfileState();
  PatientProfileState get state => _state;
  int _reloadKey = 0;
  int get reloadKey => _reloadKey;
  RealtimeChannel? _channel;

  void init(String userId) {
    loadProfile(userId);
    _channel = _repo.subscribeToProfileChanges(
      userId: userId,
      onChanged: () => loadProfile(userId),
    );
  }

  Future<void> loadProfile(String userId) async {
    try {
      final profile = await _repo.getProfile(userId);
      _state = PatientProfileState(
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        age: profile.age,
        height: profile.height,
        weight: profile.weight,
        profilePictureUrl: profile.profilePictureUrl,
        isLoading: false,
      );
      _reloadKey++;
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> saveProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required int age,
    required double heightCm,
    required double weightKg,
  }) async {
    await _repo.updateProfile(
      userId: userId,
      fullName: name,
      email: email,
      phone: phone,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    await loadProfile(userId);
  }

  Future<void> switchToGuardian(String userId) =>
      _repo.switchRole(userId, 'guardian');

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}