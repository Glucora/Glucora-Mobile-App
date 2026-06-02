import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/guardian_patient_model.dart';
import '../services/repositories/guardian_repository.dart';

// ─── REPOSITORY ───────────────────────────────────────────────────────────────

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  return GuardianRepository(Supabase.instance.client);
});

// ─── STATE ────────────────────────────────────────────────────────────────────

class GuardianPatientsState {
  final List<GuardianPatient> patients;
  final bool isLoading;
  final String? error;

  const GuardianPatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
  });

  GuardianPatientsState copyWith({
    List<GuardianPatient>? patients,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GuardianPatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  // ─── Computed getters ──────────────────────────────────────────────────────

  int get emergencyCount =>
      patients.where((p) => p.overallStatus == 'emergency').length;

  int get attentionCount =>
      patients.where((p) => p.overallStatus == 'attention').length;

  int get goodCount =>
      patients.where((p) => p.overallStatus == 'good').length;

  List<GuardianPatient> filtered(String query, String? statusFilter) {
    final result = patients.where((p) {
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.relationship.toLowerCase().contains(query.toLowerCase()) ||
          p.overallStatus.toLowerCase().contains(query.toLowerCase()) ||
          p.glucoseLabel.toLowerCase().contains(query.toLowerCase());
      final matchesStatus =
          statusFilter == null || p.overallStatus == statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    const priority = {'emergency': 0, 'attention': 1, 'good': 2};
    result.sort((a, b) =>
        (priority[a.overallStatus] ?? 2)
            .compareTo(priority[b.overallStatus] ?? 2));

    return result;
  }
}

// ─── NOTIFIER ─────────────────────────────────────────────────────────────────

class GuardianPatientsNotifier extends Notifier<GuardianPatientsState> {
  @override
  GuardianPatientsState build() => const GuardianPatientsState();

  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final patients =
          await ref.read(guardianRepositoryProvider).getPatients(userId);
      state = state.copyWith(patients: patients, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load patients: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─── PROVIDER ─────────────────────────────────────────────────────────────────

final guardianPatientsProvider =
    NotifierProvider<GuardianPatientsNotifier, GuardianPatientsState>(
        GuardianPatientsNotifier.new);