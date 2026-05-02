import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/glucose_log_model.dart';
import '../services/repositories/glucose_repository.dart';
import '../services/repositories/recommendation_repository.dart';
import '../services/repositories/prediction_repository.dart';

class GlucoseProvider extends ChangeNotifier {
  final GlucoseRepository _glucoseRepo;
  final RecommendationRepository _recommendationRepo;
  final PredictionRepository _predictionRepo;

  GlucoseProvider()
      : _glucoseRepo = GlucoseRepository(Supabase.instance.client),
        _recommendationRepo = RecommendationRepository(Supabase.instance.client),
        _predictionRepo = PredictionRepository(Supabase.instance.client);
  // ─── STATE ────────────────────────────────────────────────────────────────

int? patientProfileId;
  Map<String, dynamic>? latestReading;
  Map<String, dynamic>? latestPrediction;
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
          loadLogs(),
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