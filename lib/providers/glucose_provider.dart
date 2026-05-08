import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/glucose_log_model.dart';
import '../services/repositories/glucose_repository.dart';
import '../services/repositories/recommendation_repository.dart';
import '../services/repositories/prediction_repository.dart';
import '../services/repositories/iob_repository.dart';
import '../services/repositories/care_plan_repository.dart';
import '../services/repositories/food_log_repository.dart';
import '../core/models/food_entry_model.dart';
import '../services/repositories/device_repository.dart';
import '../services/repositories/medication_repository.dart';
import '../core/models/medication_model.dart';

class GlucoseProvider extends ChangeNotifier {
  final GlucoseRepository _glucoseRepo;
  final RecommendationRepository _recommendationRepo;
final PredictionRepository _predictionRepo;
final IobRepository _iobRepo;
final CarePlanRepository _carePlanRepo;
  final FoodLogRepository _foodLogRepo;
  final DeviceRepository _deviceRepo;
  final MedicationRepository _medicationRepo;
    GlucoseProvider()
      : _glucoseRepo = GlucoseRepository(Supabase.instance.client),
        _recommendationRepo = RecommendationRepository(Supabase.instance.client),
        _predictionRepo = PredictionRepository(Supabase.instance.client),
        _iobRepo = IobRepository(Supabase.instance.client),
        _carePlanRepo = CarePlanRepository(Supabase.instance.client),
        _foodLogRepo = FoodLogRepository(Supabase.instance.client),
      _deviceRepo = DeviceRepository(Supabase.instance.client),
              _medicationRepo = MedicationRepository(Supabase.instance.client);
  // ─── STATE ────────────────────────────────────────────────────────────────

int? patientProfileId;
  Map<String, dynamic>? latestReading;
Map<String, dynamic>? latestPrediction;
Map<String, dynamic>? latestIob;
  List<FoodEntry> foodLogs = [];
    List<Medication> medications = [];
  Map<String, dynamic>? carePlanRaw;
  String carePlanDoctorName = 'Your Doctor';
  String carePlanLastUpdated = '';
    List<GlucoseLog> logs = [];
  List<Map<String, dynamic>> recommendations = [];
  int unreadCount = 0;

  bool isLoading = false;
  String? errorMessage;

  // ─── INIT ─────────────────────────────────────────────────────────────────

  /// Call this once after login to resolve the patient profile id
  Future<void> init(String authUserId) async {
    _setLoading(true);
    try {
      patientProfileId = await _glucoseRepo.getPatientProfileId(authUserId);
      if (patientProfileId != null) {
         await Future.wait([
          loadLatestReading(),
          loadLatestPrediction(),
          loadLatestIob(),
          loadCarePlan(),
          loadLogs(),
          loadFoodLogs(),
          loadMedications(),
          loadRecommendations(),
        ]);
      }
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── GLUCOSE ──────────────────────────────────────────────────────────────
  Future<void> loadMedications() async {
    if (patientProfileId == null) return;
    try {
      medications = await _medicationRepo.getAll(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load medications: $e');
    }
  }

  Future<int?> insertMedication({
    required String name,
    String? notes,
    int? frequency,
  }) async {
    if (patientProfileId == null) return null;
    try {
      final id = await _medicationRepo.insert(
        patientProfileId: patientProfileId!,
        name: name,
        notes: notes,
        frequency: frequency,
      );
      return id;
    } catch (e) {
      _setError('Failed to insert medication: $e');
      return null;
    }
  }

  Future<int?> insertMedicationReminder({
    required int medId,
    required String remindAt,
  }) async {
    try {
      return await _medicationRepo.insertReminder(
        medId: medId,
        remindAt: remindAt,
      );
    } catch (e) {
      _setError('Failed to insert reminder: $e');
      return null;
    }
  }

  Future<void> toggleMedication(int medId, bool currentState) async {
    try {
      await _medicationRepo.toggle(medId, !currentState);
      await loadMedications();
    } catch (e) {
      _setError('Failed to toggle medication: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMedicationReminders(
      int medId) async {
    try {
      return await _medicationRepo.getReminders(medId);
    } catch (e) {
      _setError('Failed to get reminders: $e');
      return [];
    }
  }

  Future<void> deleteMedication(int medId) async {
    try {
      await _medicationRepo.deleteReminders(medId);
      await _medicationRepo.delete(medId);
      medications.removeWhere((m) => m.id == medId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete medication: $e');
    }
  }
  Future<String?> loadDeviceBattery(String userId) async {
    try {
      return await _deviceRepo.getBattery(userId);
    } catch (e) {
      _setError('Failed to load battery: $e');
      return null;
    }
  }
  
  Future<void> loadFoodLogs() async {
    if (patientProfileId == null) return;
    try {
      foodLogs = await _foodLogRepo.getTodayLogs(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load food logs: $e');
    }
  }

  Future<void> insertFoodLog({
    required String name,
    required int calories,
    double? carbs,
    double? protein,
    double? fat,
    required String mealType,
  }) async {
    if (patientProfileId == null) return;
    try {
      await _foodLogRepo.insert(
        patientProfileId: patientProfileId!,
        name: name,
        calories: calories,
        carbs: carbs,
        protein: protein,
        fat: fat,
        mealType: mealType,
      );
      await loadFoodLogs();
    } catch (e) {
      _setError('Failed to save food log: $e');
    }
  }

  Future<void> deleteFoodLog(int id) async {
    try {
      await _foodLogRepo.delete(id);
      foodLogs.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete food log: $e');
    }
  }
  Future<void> loadCarePlan() async {
    if (patientProfileId == null) return;
    try {
      final response = await _carePlanRepo.getRaw(patientProfileId!);
      if (response == null) return;

      carePlanRaw = response;
      carePlanDoctorName =
          response['doctor_profile']?['users']?['full_name'] ?? 'Your Doctor';

      final updatedAt = response['updated_at'];
      if (updatedAt != null) {
        final dt = DateTime.tryParse(updatedAt);
        if (dt != null) carePlanLastUpdated = _fmtDate(dt);
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load care plan: $e');
    }
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
  Future<void> loadLatestIob() async {
    if (patientProfileId == null) return;
    try {
      latestIob = await _iobRepo.getLatest(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load IOB: $e');
    }
  }
Future<void> loadLatestPrediction() async {
    if (patientProfileId == null) return;
    try {
      latestPrediction =
          await _predictionRepo.getLatest(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load prediction: $e');
    }
  }

  Future<bool> insertPrediction(double predictedValue) async {
    try {
      final result = await _predictionRepo.insert(predictedValue);
      if (result) await loadLatestPrediction();
      return result;
    } catch (e) {
      _setError('Failed to insert prediction: $e');
      return false;
    }
  }
  Future<void> loadLatestReading() async {
    if (patientProfileId == null) return;
    try {
      latestReading =
          await _glucoseRepo.getLatestReading(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load latest reading: $e');
    }
  }

  Future<void> loadLogs() async {
    if (patientProfileId == null) return;
    try {
      logs = await _glucoseRepo.fetchLogs(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load logs: $e');
    }
  }

  Future<void> insertLog(
    double value,
    String? notes,
    String mealTime,
  ) async {
    if (patientProfileId == null) return;
    try {
      await _glucoseRepo.insertLog(patientProfileId!, value, notes, mealTime);
      await loadLogs();
      await loadLatestReading();
    } catch (e) {
      _setError('Failed to insert log: $e');
    }
  }

  // ─── RECOMMENDATIONS ──────────────────────────────────────────────────────

  Future<void> loadRecommendations({int limit = 20}) async {
    if (patientProfileId == null) return;
    try {
      recommendations = await _recommendationRepo.getLatest(
        patientProfileId: patientProfileId!,
        limit: limit,
      );
      unreadCount = await _recommendationRepo.getUnreadCount(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: $e');
    }
  }

  Future<void> saveRecommendation({
    required String category,
    required String message,
    String? predictionId,
  }) async {
    if (patientProfileId == null) return;
    try {
      await _recommendationRepo.save(
        patientProfileId: patientProfileId!,
        category: category,
        message: message,
        predictionId: predictionId,
      );
      await loadRecommendations();
    } catch (e) {
      _setError('Failed to save recommendation: $e');
    }
  }

  Future<void> markAsRead(String recommendationId) async {
    try {
      await _recommendationRepo.markAsRead(recommendationId);
      final index =
          recommendations.indexWhere((r) => r['id'] == recommendationId);
      if (index != -1) {
        recommendations[index] = {
          ...recommendations[index],
          'is_read': true,
        };
        if (unreadCount > 0) unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark as read: $e');
    }
  }

  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      await _recommendationRepo.delete(recommendationId);
      recommendations.removeWhere((r) => r['id'] == recommendationId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete recommendation: $e');
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    if (kDebugMode) print('[GlucoseProvider] $message');
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}