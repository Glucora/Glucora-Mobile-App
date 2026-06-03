import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/core/models/glucose_log_model.dart';
import 'package:glucora_ai_companion/core/models/food_entry_model.dart';
import 'package:glucora_ai_companion/core/models/medication_model.dart';
import 'package:glucora_ai_companion/services/repositories/glucose_repository.dart';
import 'package:glucora_ai_companion/services/repositories/food_log_repository.dart';
import 'package:glucora_ai_companion/services/repositories/medication_repository.dart';
import 'package:glucora_ai_companion/services/repositories/prediction_repository.dart';
import 'package:glucora_ai_companion/services/repositories/iob_repository.dart';
import 'package:glucora_ai_companion/services/repositories/care_plan_repository.dart';
import 'package:glucora_ai_companion/services/repositories/recommendation_repository.dart';
import 'package:glucora_ai_companion/services/repositories/patient_repository.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_service.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. GLUCOSE & HISTORY
// ═══════════════════════════════════════════════════════════════════════════════

class GlucoseState {
  final List<GlucoseLog> logs;
  final Map<String, dynamic>? latestReading;
  final bool isLoading;
  final String? error;

  const GlucoseState({
    this.logs = const [],
    this.latestReading,
    this.isLoading = false,
    this.error,
  });

  GlucoseState copyWith({
    List<GlucoseLog>? logs,
    Map<String, dynamic>? latestReading,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GlucoseState(
      logs: logs ?? this.logs,
      latestReading: latestReading ?? this.latestReading,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class GlucoseNotifier extends Notifier<GlucoseState> {
  late final GlucoseRepository _repo;
  int? _patientProfileId;

  @override
  GlucoseState build() {
    _repo = GlucoseRepository(Supabase.instance.client);
    // Auto-initialize when provider is first watched
    _initialize();
    return const GlucoseState(isLoading: true);
  }

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }
    try {
      _patientProfileId = await _repo.getPatientProfileId(user.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }
    await loadLogs();
    await loadLatestReading();
  }

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      final logs = await _repo.fetchLogs(_patientProfileId!);
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadLatestReading() async {
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      final reading = await _repo.getLatestReading(_patientProfileId!);
      state = state.copyWith(latestReading: reading, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> insertLog(double value, String? notes, String mealTime) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      await _repo.insertLog(
        _patientProfileId!,
        value,
        notes,
        mealTime,
      );
      await loadLogs();
      await loadLatestReading();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteLog(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteLog(id);
      await loadLogs();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final glucoseProvider = NotifierProvider<GlucoseNotifier, GlucoseState>(
  GlucoseNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
// 2. FOOD / CALORIE LOGS
// ═══════════════════════════════════════════════════════════════════════════════

class FoodLogState {
  final List<FoodEntry> entries;
  final bool isLoading;
  final String? error;

  const FoodLogState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  FoodLogState copyWith({
    List<FoodEntry>? entries,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FoodLogState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FoodLogNotifier extends Notifier<FoodLogState> {
  late final FoodLogRepository _repo;
  int? _patientProfileId;

  @override
  FoodLogState build() {
    _repo = FoodLogRepository(Supabase.instance.client);
    _initialize();
    return const FoodLogState(isLoading: true);
  }

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }
    final glucoseRepo = GlucoseRepository(Supabase.instance.client);
    try {
      _patientProfileId = await glucoseRepo.getPatientProfileId(user.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      final entries = await _repo.getTodayLogs(_patientProfileId!);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> insert({
    required String name,
    required int calories,
    double? carbsG,
    double? proteinG,
    double? fatG,
    String? mealType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      await _repo.insert(
        name: name,
        calories: calories,
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
        mealType: mealType ?? '',
        patientProfileId: _patientProfileId!,
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> delete(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.delete(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final foodLogProvider = NotifierProvider<FoodLogNotifier, FoodLogState>(
  FoodLogNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
// 3. MEDICATIONS
// ═══════════════════════════════════════════════════════════════════════════════

class MedicationState {
  final List<Medication> medications;
  final bool isLoading;
  final String? error;

  const MedicationState({
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });

  MedicationState copyWith({
    List<Medication>? medications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MedicationNotifier extends Notifier<MedicationState> {
  late final MedicationRepository _repo;
  int? _patientProfileId;

  @override
  MedicationState build() {
    _repo = MedicationRepository(Supabase.instance.client);
    _initialize();
    return const MedicationState(isLoading: true);
  }

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }
    final glucoseRepo = GlucoseRepository(Supabase.instance.client);
    try {
      _patientProfileId = await glucoseRepo.getPatientProfileId(user.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      final meds = await _repo.getAll(_patientProfileId!);
      state = state.copyWith(medications: meds, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> insert(String name, String? notes, int? frequency) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      await _repo.insert(
        name: name,
        notes: notes,
        frequency: frequency,
        patientProfileId: _patientProfileId!,
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggle(int id, bool isActive) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.toggle(id, isActive);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> delete(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.delete(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final medicationProvider = NotifierProvider<MedicationNotifier, MedicationState>(
  MedicationNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
// 4. HOME DATA (IOB + Prediction + Recommendations + Care Plan)
// ═══════════════════════════════════════════════════════════════════════════════

class HomeDataState {
  final Map<String, dynamic>? latestReading;
  final Map<String, dynamic>? latestPrediction;
  final Map<String, dynamic>? latestIob;
  final Map<String, dynamic>? carePlan;
  final List<Map<String, dynamic>> recommendations;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const HomeDataState({
    this.latestReading,
    this.latestPrediction,
    this.latestIob,
    this.carePlan,
    this.recommendations = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  HomeDataState copyWith({
    Map<String, dynamic>? latestReading,
    Map<String, dynamic>? latestPrediction,
    Map<String, dynamic>? latestIob,
    Map<String, dynamic>? carePlan,
    List<Map<String, dynamic>>? recommendations,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HomeDataState(
      latestReading: latestReading ?? this.latestReading,
      latestPrediction: latestPrediction ?? this.latestPrediction,
      latestIob: latestIob ?? this.latestIob,
      carePlan: carePlan ?? this.carePlan,
      recommendations: recommendations ?? this.recommendations,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class HomeDataNotifier extends Notifier<HomeDataState> {
  late final PredictionRepository _predictionRepo;
  late final IobRepository _iobRepo;
  late final CarePlanRepository _carePlanRepo;
  late final RecommendationRepository _recommendationRepo;
  late final GlucoseRepository _glucoseRepo;
  int? _patientProfileId;

  @override
  HomeDataState build() {
    _predictionRepo = PredictionRepository(Supabase.instance.client);
    _iobRepo = IobRepository(Supabase.instance.client);
    _carePlanRepo = CarePlanRepository(Supabase.instance.client);
    _recommendationRepo = RecommendationRepository(Supabase.instance.client);
    _glucoseRepo = GlucoseRepository(Supabase.instance.client);
    _initialize();
    return const HomeDataState(isLoading: true);
  }

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }
    try {
      _patientProfileId = await _glucoseRepo.getPatientProfileId(user.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }
    await refresh();
  }
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final results = await Future.wait([
        _glucoseRepo.getLatestReading(_patientProfileId!),     // int — correct
        _predictionRepo.getLatest(),                              // uses auth UUID internally — correct
        _iobRepo.getLatest(_patientProfileId!),                  // int — correct
        _carePlanRepo.getRaw(_patientProfileId!),                // int — correct
        _recommendationRepo.getLatest(patientProfileId: userId), // ← FIX: was _patientProfileId.toString() (int), now userId (UUID)
        _recommendationRepo.getUnreadCount(),                    // uses auth UUID internally — correct
      ]);

      state = state.copyWith(
        latestReading: results[0] as Map<String, dynamic>?,
        latestPrediction: results[1] as Map<String, dynamic>?,
        latestIob: results[2] as Map<String, dynamic>?,
        carePlan: results[3] as Map<String, dynamic>?,
        recommendations: (results[4] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        unreadCount: results[5] as int? ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadCarePlan() async {
    try {
      if (_patientProfileId == null) {
        throw Exception('Patient profile id not set');
      }
      final plan = await _carePlanRepo.getRaw(_patientProfileId!);
      state = state.copyWith(carePlan: plan, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markRecommendationRead(String id) async {
    try {
      await _recommendationRepo.markAsRead(id);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final homeDataProvider = NotifierProvider<HomeDataNotifier, HomeDataState>(
  HomeDataNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
// 5. PATIENT PROFILE
// ═══════════════════════════════════════════════════════════════════════════════

class PatientProfileNotifier extends Notifier<PatientProfile?> {
  late final PatientRepository _repo;
  RealtimeChannel? _channel;
  String? _userId;

  @override
  PatientProfile? build() {
    _repo = PatientRepository(Supabase.instance.client);
    ref.onDispose(() => _channel?.unsubscribe());
    _initialize();
    return null;
  }

  Future<void> _initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await load(user.id);
  }

  Future<void> load(String userId) async {
    _userId = userId;
    try {
      final profile = await _repo.getProfile(userId);
      state = profile;
      _subscribeToChanges(userId);
    } catch (e) {
      state = null;
    }
  }

  Future<void> update({
    required String name,
    required int age,
    required String email,
    required String phone,
    required double heightCm,
    required double weightKg,
  }) async {
    try {
      final userId = _userId ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No user ID available');

      await _repo.updateProfile(
        userId: userId,
        fullName: name,
        email: email,
        phone: phone,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
      );
      await load(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> switchToGuardian() async {
    try {
      final userId = _userId ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No user ID available');

      await _repo.switchRole(userId, 'guardian');
    } catch (e) {
      rethrow;
    }
  }

  void _subscribeToChanges(String userId) {
    _channel = _repo.subscribeToProfileChanges(
      userId: userId,
      onChanged: () => load(userId),
    );
  }
}

final patientProfileProvider = NotifierProvider<PatientProfileNotifier, PatientProfile?>(
  PatientProfileNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════════
// 6. BLE / DEVICE DATA (StreamProvider)
// ═══════════════════════════════════════════════════════════════════════════════

final bleDataProvider = StreamProvider<BleHardwareData>((ref) {
  return BleHardwareService.instance.dataStream;
});