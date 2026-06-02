// lib/providers/doctor_riverpod_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/services/repositories/doctor_repository.dart';

// ─────────────────────────────────────────────────────────────
// DoctorPatientsState  (immutable snapshot)
// ─────────────────────────────────────────────────────────────
class DoctorPatientsState {
  final List<DoctorPatient> allPatients;
  final String doctorName;
  final bool isLoading;
  final String? error;
  final String query;
  final String? filterStatus;
  final String? filterTrend;
  final String? filterRange;

  const DoctorPatientsState({
    this.allPatients = const [],
    this.doctorName = '',
    this.isLoading = true,
    this.error,
    this.query = '',
    this.filterStatus,
    this.filterTrend,
    this.filterRange,
  });

  bool get hasActiveFilters =>
      filterStatus != null || filterTrend != null || filterRange != null;

  String _glucoseRange(DoctorPatient p) {
    if (p.glucoseValue < 70) return 'Low';
    if (p.glucoseValue <= 180) return 'In Range';
    return 'High';
  }

  List<DoctorPatient> get filtered {
    return allPatients.where((p) {
      if (query.isNotEmpty &&
          !p.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      if (filterStatus != null && p.status != filterStatus) return false;
      if (filterTrend != null && p.trend != filterTrend) return false;
      if (filterRange != null && _glucoseRange(p) != filterRange) return false;
      return true;
    }).toList();
  }

  DoctorPatientsState copyWith({
    List<DoctorPatient>? allPatients,
    String? doctorName,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? query,
    String? filterStatus,
    bool clearFilterStatus = false,
    String? filterTrend,
    bool clearFilterTrend = false,
    String? filterRange,
    bool clearFilterRange = false,
  }) {
    return DoctorPatientsState(
      allPatients: allPatients ?? this.allPatients,
      doctorName: doctorName ?? this.doctorName,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterTrend: clearFilterTrend ? null : (filterTrend ?? this.filterTrend),
      filterRange: clearFilterRange ? null : (filterRange ?? this.filterRange),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DoctorPatientsNotifier
// ─────────────────────────────────────────────────────────────
class DoctorPatientsNotifier extends Notifier<DoctorPatientsState> {
  late final DoctorRepository _repo;

  @override
  DoctorPatientsState build() {
    _repo = DoctorRepository(Supabase.instance.client);
    // Kick off initial load right after build
    Future.microtask(() => _init());
    return const DoctorPatientsState();
  }

  Future<void> _init() async {
    _loadDoctorName();
    await loadPatients();
  }

  void _loadDoctorName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final fullName = user.userMetadata?['full_name'] as String?;
    state = state.copyWith(doctorName: fullName ?? 'Doctor');
  }

  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final patients = await _repo.getPatients(userId);
      state = state.copyWith(allPatients: patients, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void applyFilters({
    String? filterStatus,
    String? filterTrend,
    String? filterRange,
    bool clearAll = false,
  }) {
    if (clearAll) {
      state = state.copyWith(
        clearFilterStatus: true,
        clearFilterTrend: true,
        clearFilterRange: true,
      );
      return;
    }
    state = state.copyWith(
      filterStatus: filterStatus,
      clearFilterStatus: filterStatus == null,
      filterTrend: filterTrend,
      clearFilterTrend: filterTrend == null,
      filterRange: filterRange,
      clearFilterRange: filterRange == null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────
final doctorPatientsProvider =
    NotifierProvider<DoctorPatientsNotifier, DoctorPatientsState>(
  DoctorPatientsNotifier.new,
);