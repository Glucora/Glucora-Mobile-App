// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/providers/glucose_provider.dart
// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW:
// This is the central state management class for the entire patient-facing
// portion of the app. It extends ChangeNotifier (from Flutter's foundation
// library) which provides a publish-subscribe pattern: when data changes,
// notifyListeners() is called, and all listening widgets automatically rebuild.
//
// The provider acts as a bridge between the UI (screens/widgets) and the
// data layer (repositories that talk to Supabase). It centralizes all patient
// data operations so screens don't directly interact with the database.
//
// ARCHITECTURE PATTERN: Provider + ChangeNotifier
// - The UI calls methods on this provider
// - The provider delegates to repositories (data layer)
// - Repositories perform Supabase queries
// - The provider updates local state and calls notifyListeners()
// - Listening widgets (via Consumer or context.watch) rebuild with new data
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// CLASS: GlucoseProvider
// PURPOSE: Central state manager that exposes app-level patient data to the UI.
//          All screens interact with this class instead of directly calling
//          repositories or Supabase. This ensures:
//          - Single source of truth for patient data
//          - Consistent error handling across the app
//          - Loading state management
//          - UI automatically updates when data changes (via notifyListeners)
//
// REPOSITORIES: Each repository handles one domain (glucose, food, meds, etc.)
//               and encapsulates all Supabase queries for that domain.
//               This follows the Repository Pattern for clean architecture.
// ═══════════════════════════════════════════════════════════════════════════════
class GlucoseProvider extends ChangeNotifier {

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Repository Instances
  // PURPOSE: Each repository is initialized with the global Supabase client
  //          instance. Repositories are created in the constructor and exist
  //          for the lifetime of the provider. They handle all database
  //          operations (CRUD) for their respective domains.
  // ═══════════════════════════════════════════════════════════════════════════════
  final GlucoseRepository _glucoseRepo;
  final RecommendationRepository _recommendationRepo;
  final PredictionRepository _predictionRepo;
  final IobRepository _iobRepo;
  final CarePlanRepository _carePlanRepo;
  final FoodLogRepository _foodLogRepo;
  final DeviceRepository _deviceRepo;
  final MedicationRepository _medicationRepo;

  // ═══════════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // PURPOSE: Initializes all repository instances with the singleton Supabase
  //          client. This is called once when the provider is created (typically
  //          at app startup via ChangeNotifierProvider in main.dart).
  // ═══════════════════════════════════════════════════════════════════════════════
  GlucoseProvider()
    : _glucoseRepo = GlucoseRepository(Supabase.instance.client),
      _recommendationRepo = RecommendationRepository(Supabase.instance.client),
      _predictionRepo = PredictionRepository(Supabase.instance.client),
      _iobRepo = IobRepository(Supabase.instance.client),
      _carePlanRepo = CarePlanRepository(Supabase.instance.client),
      _foodLogRepo = FoodLogRepository(Supabase.instance.client),
      _deviceRepo = DeviceRepository(Supabase.instance.client),
      _medicationRepo = MedicationRepository(Supabase.instance.client);

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: State Fields
  // PURPOSE: These are the reactive data fields that the UI listens to.
  //          When any of these change, notifyListeners() is called, causing
  //          all Consumer<GlucoseProvider> widgets to rebuild.
  //
  //          patientProfileId: Links the auth user to their patient record
  //          latestReading: Most recent glucose reading from Supabase
  //          latestPrediction: Most recent AI glucose prediction
  //          latestIob: Current insulin-on-board value
  //          foodLogs: Today's food entries for calorie tracking
  //          medications: All patient medications with reminders
  //          carePlanRaw: Full care plan data from Supabase
  //          carePlanDoctorName: Extracted doctor name for quick access
  //          carePlanLastUpdated: Formatted last update date
  //          logs: All glucose logs (for history screens)
  //          recommendations: AI-generated health recommendations
  //          unreadCount: Number of unread recommendations (for badge)
  //          authUserId: The Supabase auth UUID
  //          isLoading: Global loading flag for UI spinners
  //          errorMessage: Last error for display in UI
  // ═══════════════════════════════════════════════════════════════════════════════
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
  String? authUserId;

  bool isLoading = false;
  String? errorMessage;

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Initialization
  // PURPOSE: Sets up the provider for a specific user. This method:
  //          1. Sets the global loading state (shows spinners in UI)
  //          2. Stores the auth user ID for later use
  //          3. Fetches the patient profile ID from Supabase (links auth user
  //             to their patient record in the patients table)
  //          4. If profile exists, loads ALL patient data in parallel using
  //             Future.wait() for efficiency (concurrent network calls)
  //          5. Handles errors and clears loading state regardless of outcome
  //
  //          Future.wait() is used instead of sequential awaits because all
  //          these data fetches are independent — they don't depend on each
  //          other's results, so running them concurrently is much faster.
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> init(String userId) async {
    _setLoading(true);
    authUserId = userId;
    try {
      patientProfileId = await _glucoseRepo.getPatientProfileId(userId);
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Medications
  // PURPOSE: CRUD operations for patient medications and their reminder schedules.
  //          These methods delegate to MedicationRepository and update the local
  //          medications list, triggering UI rebuilds via notifyListeners().
  //
  //          loadMedications(): Fetches all medications for the patient
  //          insertMedication(): Creates a new medication, returns its ID
  //          insertMedicationReminder(): Adds a time reminder to a medication
  //          toggleMedication(): Flips the active flag (enables/disables)
  //          getMedicationReminders(): Fetches all reminders for a medication
  //          deleteMedication(): Removes medication and all its reminders
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadMedications()
  // PURPOSE: Fetches all medications for the current patient from Supabase
  //          and stores them in the medications list. Called during init()
  //          and after any medication modification.
  Future<void> loadMedications() async {
    if (patientProfileId == null) return;
    try {
      medications = await _medicationRepo.getAll(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load medications: $e');
    }
  }

  // METHOD: insertMedication()
  // PURPOSE: Creates a new medication record in Supabase. Returns the new
  //          medication's ID so the caller can immediately add reminders to it.
  //          The ID is needed because reminders reference medications via
  //          foreign key.
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

  // METHOD: insertMedicationReminder()
  // PURPOSE: Adds a reminder time to an existing medication. The remindAt
  //          parameter is a "HH:MM:SS" string. Returns the new reminder's ID
  //          which is used to generate the deterministic notification ID.
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

  // METHOD: toggleMedication()
  // PURPOSE: Flips the is_active boolean for a medication. After toggling
  //          in the database, it reloads all medications to keep the UI
  //          in sync. The UI calls this when the user taps a Switch widget.
  Future<void> toggleMedication(int medId, bool currentState) async {
    try {
      await _medicationRepo.toggle(medId, !currentState);
      await loadMedications();
    } catch (e) {
      _setError('Failed to toggle medication: $e');
    }
  }

  // METHOD: getMedicationReminders()
  // PURPOSE: Fetches all reminder records for a specific medication.
  //          Returns a list of maps containing reminder IDs and times.
  //          Used by the UI to display reminder chips and by notification
  //          scheduling to get reminder IDs for cancellation.
  Future<List<Map<String, dynamic>>> getMedicationReminders(int medId) async {
    try {
      return await _medicationRepo.getReminders(medId);
    } catch (e) {
      _setError('Failed to get reminders: $e');
      return [];
    }
  }

  // METHOD: deleteMedication()
  // PURPOSE: Permanently removes a medication and all its reminders.
  //          First deletes reminders (to avoid foreign key constraint errors),
  //          then deletes the medication. Also removes it from the local
  //          medications list immediately for responsive UI.
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Device Management
  // PURPOSE: Handles connected device metadata such as battery health.
  //          Currently only supports battery level fetching. Future expansion
  //          could include device pairing status, firmware version, etc.
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadDeviceBattery()
  // PURPOSE: Fetches the battery health string for the user's connected
  //          glucose sensor/pump device. Returns null if no device is paired
  //          or if the query fails.
  Future<String?> loadDeviceBattery(String userId) async {
    try {
      return await _deviceRepo.getBattery(userId);
    } catch (e) {
      _setError('Failed to load battery: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Food Logs
  // PURPOSE: Manages daily food/calorie entries with macro nutrient tracking.
  //          These methods support the CalorieLogScreen's full functionality:
  //          viewing today's entries, adding new ones, and deleting existing ones.
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadFoodLogs()
  // PURPOSE: Fetches all food entries logged today for the current patient.
  //          The repository filters by date server-side for efficiency.
  //          Results are stored in foodLogs and trigger UI rebuild.
  Future<void> loadFoodLogs() async {
    if (patientProfileId == null) return;
    try {
      foodLogs = await _foodLogRepo.getTodayLogs(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load food logs: $e');
    }
  }

  // METHOD: insertFoodLog()
  // PURPOSE: Creates a new food entry in Supabase and refreshes the food log
  //          list. All macro parameters (carbs, protein, fat) are optional
  //          and stored as null if not provided. After insertion, loadFoodLogs()
  //          is called to update the UI with the new entry.
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

  // METHOD: deleteFoodLog()
  // PURPOSE: Removes a food entry by its ID and updates the local list
  //          immediately (optimistic update) before the UI rebuilds.
  Future<void> deleteFoodLog(int id) async {
    try {
      await _foodLogRepo.delete(id);
      foodLogs.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete food log: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Care Plan
  // PURPOSE: Loads and formats the patient's care plan from Supabase.
  //          The care plan includes doctor information, target glucose range,
  //          and next appointment date. Data is stored as a raw map (carePlanRaw)
  //          and also extracted into convenient string fields for quick UI access.
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadCarePlan()
  // PURPOSE: Fetches the patient's care plan with a joined doctor_profile
  //          query (using Supabase's foreign key relationships). Extracts:
  //          - Doctor's full name from nested users table
  //          - Formatted last updated date
  //          Stores the raw response for other screens that need full data.
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

  // METHOD: _fmtDate()
  // PURPOSE: Formats a DateTime into "Mon DD, YYYY" format for display.
  //          Uses a hardcoded month abbreviation array. Private helper method.
  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Insulin On Board (IOB)
  // PURPOSE: Fetches the latest active insulin reading for the patient.
  //          IOB represents how much insulin is still active in the patient's
  //          system from previous bolus doses. This is critical for avoiding
  //          insulin stacking (taking too much insulin too close together).
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadLatestIob()
  // PURPOSE: Fetches the most recent IOB record for the patient from Supabase.
  //          The result is stored as a Map for flexible field access.
  Future<void> loadLatestIob() async {
    if (patientProfileId == null) return;
    try {
      latestIob = await _iobRepo.getLatest(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load IOB: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: AI Predictions
  // PURPOSE: Manages glucose prediction data from the AI backend.
  //          Predictions forecast future glucose levels based on current trends,
  //          food intake, insulin doses, and other factors. Used by the
  //          HomeScreen's prediction card and the dedicated AIPredictionScreen.
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadLatestPrediction()
  // PURPOSE: Fetches the most recent AI prediction. Uses authUserId instead
  //          of patientProfileId because predictions may be generated at the
  //          user/auth level rather than the patient profile level.
  Future<void> loadLatestPrediction() async {
    if (authUserId == null) return;
    try {
      latestPrediction = await _predictionRepo.getLatest();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load prediction: $e');
    }
  }

  // METHOD: insertPrediction()
  // PURPOSE: Saves a new AI prediction value to Supabase and refreshes the
  //          latest prediction. Returns true on success. Typically called by
  //          background processes or the AI service, not directly by user action.
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Glucose Logs
  // PURPOSE: CRUD operations for manual glucose readings. These support the
  //          ManualLogScreen and provide data for the HomeScreen's chart.
  //          All values are stored in mg/dL in the database; unit conversion
  //          happens in the UI layer (ManualLogScreen).
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadLatestReading()
  // PURPOSE: Fetches the most recent glucose reading for the patient.
  //          Used by the HomeScreen to display current glucose level.
  Future<void> loadLatestReading() async {
    if (patientProfileId == null) return;
    try {
      latestReading = await _glucoseRepo.getLatestReading(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load latest reading: $e');
    }
  }

  // METHOD: loadLogs()
  // PURPOSE: Fetches all glucose logs for the patient (not just latest).
  //          Used by ManualLogScreen to display the full history and by
  //          HomeScreen's chart to show the past hour of readings.
  Future<void> loadLogs() async {
    if (patientProfileId == null) return;
    try {
      logs = await _glucoseRepo.fetchLogs(patientProfileId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load logs: $e');
    }
  }

  // METHOD: insertLog()
  // PURPOSE: Creates a new glucose log entry in Supabase and refreshes both
  //          the full log list and the latest reading. The value is expected
  //          to already be in mg/dL (conversion happens in the UI).
  //          Rethrows the error so the UI can show a SnackBar with details.
  Future<void> insertLog(double value, String? notes, String mealTime) async {
    if (patientProfileId == null) return;
    try {
      await _glucoseRepo.insertLog(patientProfileId!, value, notes, mealTime);
      await loadLogs();
      await loadLatestReading();
    } catch (e) {
      _setError('Failed to insert log: $e');
      rethrow;
    }
  }

  // METHOD: deleteLog()
  // PURPOSE: Removes a glucose log by its string ID and updates the local
  //          logs list immediately (optimistic update). Called by the
  //          ManualLogScreen's swipe-to-delete feature.
  Future<void> deleteLog(String id) async {
    try {
      await _glucoseRepo.deleteLog(id);
      logs.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete log: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Recommendations
  // PURPOSE: Manages AI-generated health recommendations displayed to the patient.
  //          Recommendations have categories, messages, and read/unread status.
  //          The replaceRecommendations method implements an atomic swap:
  //          save new recommendations first, then delete old ones, so the user
  //          never sees an empty state during the transition.
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: loadRecommendations()
  // PURPOSE: Fetches the latest recommendations for the user, limited to a
  //          configurable number (default 3 for the HomeScreen preview).
  //          Also counts unread recommendations for badge display.
  Future<void> loadRecommendations({int limit = 3}) async {
    if (authUserId == null) return;
    try {
      recommendations = await _recommendationRepo.getLatest(
        patientProfileId: authUserId!,
        limit: limit,
      );
      unreadCount =
          recommendations.where((r) => r['is_read'] == false).length;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: $e');
    }
  }

  // METHOD: replaceRecommendations()
  // PURPOSE: Atomically replaces all recommendations with a new batch.
  //          The algorithm:
  //          1. Save each new recommendation to Supabase
  //          2. Collect the IDs of successfully saved recommendations
  //          3. Delete all OLD recommendations except the newly saved ones
  //          4. Re-fetch from database (don't trust insert responses)
  //          5. Update unread count and notify listeners
  //          This "save-then-delete" order ensures the user never sees an
  //          empty recommendations list during the swap.
  Future<void> replaceRecommendations({
    required List<Map<String, String>> recs,
  }) async {
    if (authUserId == null) return;
    try {
      final newIds = <String>[];
      final newRows = <Map<String, dynamic>>[];

      for (final rec in recs) {
        final saved = await _recommendationRepo.save(
          patientProfileId: authUserId!,
          category: rec['category']!,
          message: rec['message']!,
        );
        if (saved != null) {
          newIds.add(saved['id'].toString());
          newRows.add(saved);
        }
      }

      if (newIds.isNotEmpty) {
        await _recommendationRepo.deleteAllExcept(
          patientProfileId: authUserId!,
          keepIds: newIds,
        );
      }

      // Re-fetch from DB instead of trusting the insert response
      recommendations = await _recommendationRepo.getLatest(
        patientProfileId: authUserId!,
        limit: 3,
      );
      unreadCount = recommendations.where((r) => r['is_read'] == false).length;
      notifyListeners();

    } catch (e) {
      _setError('Failed to replace recommendations: $e');
    }
  }

  // METHOD: markAsRead()
  // PURPOSE: Marks a specific recommendation as read in Supabase and updates
  //          the local state immediately (optimistic update). Decrements
  //          the unread count for badge updates.
  Future<void> markAsRead(String recommendationId) async {
    try {
      await _recommendationRepo.markAsRead(recommendationId);
      final index = recommendations.indexWhere(
        (r) => r['id'] == recommendationId,
      );
      if (index != -1) {
        recommendations[index] = {...recommendations[index], 'is_read': true};
        if (unreadCount > 0) unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark as read: $e');
    }
  }

  // METHOD: deleteRecommendation()
  // PURPOSE: Permanently removes a recommendation from Supabase and the
  //          local list. Called from the RecommendationsScreen's delete action.
  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      await _recommendationRepo.delete(recommendationId);
      recommendations.removeWhere((r) => r['id'] == recommendationId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete recommendation: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Internal Helpers
  // PURPOSE: Private utility methods for managing loading states, error handling,
  //          and logging. These keep the public API clean and ensure consistent
  //          behavior across all data operations.
  // ═══════════════════════════════════════════════════════════════════════════════

  // METHOD: _setLoading()
  // PURPOSE: Sets the global isLoading flag and triggers a UI rebuild.
  //          All async operations in this provider should wrap their work
  //          in _setLoading(true) ... _setLoading(false) to show/hide
  //          loading indicators in the UI.
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // METHOD: _setError()
  // PURPOSE: Stores an error message and logs it to the console in debug mode.
  //          The errorMessage is displayed in the UI (e.g., MedicationScreen
  //          shows it as red text). Also triggers a rebuild so the error
  //          appears immediately.
  void _setError(String message) {
    errorMessage = message;
    if (kDebugMode) print('[GlucoseProvider] $message');
    notifyListeners();
  }

  // METHOD: clearError()
  // PURPOSE: Clears the current error message. Called by screens when the
  //          user dismisses an error or starts a new operation.
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}