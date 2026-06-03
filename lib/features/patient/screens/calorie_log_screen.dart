// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/features/patient/screens/calorie_log_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW:
// This screen allows patients to track their daily food intake. It features a
// calorie goal progress tracker with circular indicator, macro nutrient breakdown
// (carbs, protein, fat), and a list of food entries with add/edit/delete functionality.
// Food entries are persisted to Supabase and support swipe-to-delete with undo.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/providers/glucose_provider.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/models/food_entry_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: CalorieLogScreen (StatefulWidget)
// PURPOSE: Creates a stateful screen for calorie/food tracking. The state object
//          manages form controllers, selected meal type, and save operation state.
//          This follows the Flutter pattern where StatefulWidget is lightweight
//          and the State object holds all mutable data.
// ═══════════════════════════════════════════════════════════════════════════════
class CalorieLogScreen extends StatefulWidget {
  const CalorieLogScreen({super.key});

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE: _CalorieLogScreenState
// PURPOSE: Manages all mutable state for the Calorie Log screen including:
//          - TextEditingControllers for all form fields (name, calories, macros)
//          - GlobalKey<FormState> for form validation
//          - Selected meal type from the chip options
//          - Loading and error states for async operations
// ═══════════════════════════════════════════════════════════════════════════════
class _CalorieLogScreenState extends State<CalorieLogScreen> {

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Form State & Controllers
  // PURPOSE: These controllers manage user input for food entries:
  //          - _nameController: the food item name (e.g., "Chicken Salad")
  //          - _calController: calorie count (required, must be positive integer)
  //          - _carbsController: carbohydrate grams (optional)
  //          - _proteinController: protein grams (optional)
  //          - _fatController: fat grams (optional)
  //          _formKey is used by Flutter's Form widget to validate all fields
  //          at once when the user submits. _saving prevents double-submit.
  //          _dailyGoal is a hardcoded target of 2000 kcal (could be configurable).
  // ═══════════════════════════════════════════════════════════════════════════════
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  static const int _dailyGoal = 2000;
  String _selectedMeal = 'Snack';
  static const _mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  bool _saving = false;
  String? _error;

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Input Validators
  // PURPOSE: Three validator functions for different field requirements:
  //          - _requiredValidator: checks that a field is not empty/whitespace
  //          - _positiveNumberValidator: ensures the value is a valid number >= 0
  //          - _optionalPositiveNumber: same as above but returns null (valid)
  //            for empty fields, since carbs/protein/fat are optional
  //          These are passed to each TextFormField's validator property and
  //          automatically invoked when _formKey.currentState!.validate() is called.
  // ═══════════════════════════════════════════════════════════════════════════════
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _positiveNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Must be a number';
    if (n < 0) return 'Must be ≥ 0';
    return null;
  }

  String? _optionalPositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim());
    if (n == null) return 'Must be a number';
    if (n < 0) return 'Must be ≥ 0';
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE: initState()
  // PURPOSE: Called once when the widget is first built. We defer provider
  //          initialization using Future.microtask to avoid side effects during
  //          the build phase. This ensures the widget is fully mounted before
  //          calling context.read() to access the GlucoseProvider.
  // ═══════════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE: dispose()
  // PURPOSE: Called when the widget is permanently removed. We dispose ALL
  //          TextEditingControllers to release native platform resources and
  //          prevent memory leaks. This is critical for any StatefulWidget
  //          that uses text input fields.
  // ═══════════════════════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _nameController.dispose();
    _calController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _init()
  // PURPOSE: Initializes the provider state for this screen. If patientProfileId
  //          is not yet set (first visit), it fetches it from Supabase using
  //          the authenticated user's ID via provider.init(). Otherwise, it
  //          directly loads today's food logs. This ensures data is available
  //          when the UI renders.
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> _init() async {
    final provider = context.read<GlucoseProvider>();
    if (provider.patientProfileId == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await provider.init(user.id);
    } else {
      await provider.loadFoodLogs();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Computed Values
  // PURPOSE: Helper methods that calculate aggregate values from the food log list:
  //          - _total(): sums all calories across entries using fold
  //          - _progress(): calculates completion percentage (0.0 to 1.0) against
  //            the daily goal, clamped to prevent overflow beyond 100%
  //          - _totalCarbs/Protein/Fat(): sums each macro nutrient using fold
  //          These are called during build() to update the summary card dynamically.
  // ═══════════════════════════════════════════════════════════════════════════════
  int _total(List<FoodEntry> entries) =>
      entries.fold(0, (s, e) => s + e.calories);

  double _progress(List<FoodEntry> entries) =>
      (_total(entries) / _dailyGoal).clamp(0.0, 1.0);

  double _totalCarbs(List<FoodEntry> entries) =>
      entries.fold(0.0, (s, e) => s + (e.carbsG ?? 0));

  double _totalProtein(List<FoodEntry> entries) =>
      entries.fold(0.0, (s, e) => s + (e.proteinG ?? 0));

  double _totalFat(List<FoodEntry> entries) =>
      entries.fold(0.0, (s, e) => s + (e.fatG ?? 0));

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Add Food Entry
  // PURPOSE: Validates the form, extracts all field values, and persists a new
  //          food entry to Supabase via GlucoseProvider.insertFoodLog().
  //          The flow:
  //          1. Check _formKey.currentState!.validate() runs all field validators
  //          2. Guard against double-submit with _saving flag
  //          3. Parse required fields (name, calories) and optional macros
  //          4. Call provider.insertFoodLog() which saves to Supabase and refreshes
  //          5. Clear all controllers and reset meal type to default
  //          6. Close the bottom sheet on success
  //          7. Handle errors by setting _error state
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> _addEntry() async {
    if (!_formKey.currentState!.validate()) return;

    // Guard against double-tap while already saving
    if (_saving) return;

    final name = _nameController.text.trim();
    final cal = int.tryParse(_calController.text.trim());
    if (name.isEmpty || cal == null) return;

    final carbs = double.tryParse(_carbsController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<GlucoseProvider>().insertFoodLog(
            name: name,
            calories: cal,
            carbs: carbs,
            protein: protein,
            fat: fat,
            mealType: _selectedMeal,
          );

      _nameController.clear();
      _calController.clear();
      _carbsController.clear();
      _proteinController.clear();
      _fatController.clear();
      setState(() => _selectedMeal = 'Snack');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Delete with Undo
  // PURPOSE: Handles deletion of a food entry with Material Design undo pattern.
  //          When called:
  //          1. Deletes the entry from Supabase via provider.deleteFoodLog()
  //          2. Shows a SnackBar with the deleted item name and an "Undo" action
  //          3. If user taps "Undo", re-inserts the entry with all original data
  //          This prevents accidental data loss and follows UX best practices.
  //          We clear existing snackbars first to avoid stacking multiple messages.
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> _deleteEntry(BuildContext ctx, FoodEntry entry) async {
    if (entry.id == null) return;
    final provider = ctx.read<GlucoseProvider>();

    // Optimistic remove
    await provider.deleteFoodLog(entry.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('${entry.name} deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Restore by re-inserting
            await provider.insertFoodLog(
              name: entry.name,
              calories: entry.calories,
              carbs: entry.carbsG,
              protein: entry.proteinG,
              fat: entry.fatG,
              mealType: entry.mealType ?? 'Snack',
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Edit Entry Sheet
  // PURPOSE: Displays a bottom sheet modal for editing an existing food entry.
  //          It pre-populates all fields with the entry's current values and
  //          allows the user to modify any field. The save flow:
  //          1. Validates the edit form
  //          2. Deletes the old entry
  //          3. Inserts a new entry with updated values
  //          4. Closes the sheet on success
  //          Uses StatefulBuilder so the bottom sheet can have its own setState
  //          independent of the parent screen's state.
  // ═══════════════════════════════════════════════════════════════════════════════
  void _showEditSheet(BuildContext context, FoodEntry entry) {
    final editNameCtrl = TextEditingController(text: entry.name);
    final editCalCtrl =
        TextEditingController(text: entry.calories.toString());
    final editCarbsCtrl = TextEditingController(
        text: entry.carbsG?.toStringAsFixed(1) ?? '');
    final editProteinCtrl = TextEditingController(
        text: entry.proteinG?.toStringAsFixed(1) ?? '');
    final editFatCtrl =
        TextEditingController(text: entry.fatG?.toStringAsFixed(1) ?? '');
    String editMeal = entry.mealType ?? 'Snack';
    final editFormKey = GlobalKey<FormState>();
    bool editSaving = false;

    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TranslatedText('Edit Food Entry',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  const SizedBox(height: 20),
                  _field(ctx, editNameCtrl, 'Food name',
                      Icons.fastfood_rounded,
                      validator: _requiredValidator),
                  const SizedBox(height: 12),
                  _field(ctx, editCalCtrl, 'Calories (kcal)',
                      Icons.local_fire_department_rounded,
                      type: TextInputType.number,
                      validator: _positiveNumberValidator),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field(ctx, editCarbsCtrl, 'Carbs (g)',
                            Icons.grain_rounded,
                            type: TextInputType.number,
                            validator: _optionalPositiveNumber)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(ctx, editProteinCtrl, 'Protein (g)',
                            Icons.fitness_center_rounded,
                            type: TextInputType.number,
                            validator: _optionalPositiveNumber)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(ctx, editFatCtrl, 'Fat (g)',
                            Icons.opacity_rounded,
                            type: TextInputType.number,
                            validator: _optionalPositiveNumber)),
                  ]),
                  const SizedBox(height: 16),
                  TranslatedText('Meal type',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _mealOptions.map((mt) {
                      final sel = editMeal == mt;
                      return GestureDetector(
                        onTap: () => setSheet(() => editMeal = mt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? colors.primary : colors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TranslatedText(mt,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: sel
                                      ? Colors.white
                                      : colors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: editSaving
                          ? null
                          : () async {
                              if (!editFormKey.currentState!.validate()) {
                                return;
                              }
                              setSheet(() => editSaving = true);
                              try {
                                final provider =
                                    ctx.read<GlucoseProvider>();
                                // Delete old then re-insert with new values
                                if (entry.id != null) {
                                  await provider.deleteFoodLog(entry.id!);
                                }
                                await provider.insertFoodLog(
                                  name: editNameCtrl.text.trim(),
                                  calories: int.tryParse(
                                          editCalCtrl.text.trim()) ??
                                      entry.calories,
                                  carbs: double.tryParse(
                                      editCarbsCtrl.text.trim()),
                                  protein: double.tryParse(
                                      editProteinCtrl.text.trim()),
                                  fat: double.tryParse(
                                      editFatCtrl.text.trim()),
                                  mealType: editMeal,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (_) {
                                setSheet(() => editSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: editSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const TranslatedText('Save Changes',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Add Entry Bottom Sheet
  // PURPOSE: Displays a modal bottom sheet for creating new food entries.
  //          Uses StatefulBuilder to maintain independent state within the sheet.
  //          Features:
  //          - Drag handle indicator at the top (Material Design pattern)
  //          - Form with all fields (name, calories, macros)
  //          - Meal type chips for quick selection
  //          - Save button with loading state
  //          - Keyboard-aware padding (viewInsets.bottom) so the sheet doesn't
  //            get hidden by the on-screen keyboard
  //          The sheet is scrollable to accommodate smaller screens.
  // ═══════════════════════════════════════════════════════════════════════════════
  void _showAddSheet(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TranslatedText('Add Food Entry',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  const SizedBox(height: 20),
                  _field(ctx, _nameController, 'Food name',
                      Icons.fastfood_rounded,
                      validator: _requiredValidator),
                  const SizedBox(height: 12),
                  _field(ctx, _calController, 'Calories (kcal)',
                      Icons.local_fire_department_rounded,
                      type: TextInputType.number,
                      validator: _positiveNumberValidator),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field(ctx, _carbsController, 'Carbs (g)',
                            Icons.grain_rounded,
                            type: TextInputType.number,
                            validator: _optionalPositiveNumber)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(ctx, _proteinController, 'Protein (g)',
                            Icons.fitness_center_rounded,
                            type: TextInputType.number,
                            validator: _optionalPositiveNumber)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(ctx, _fatController, 'Fat (g)',
                            Icons.opacity_rounded,
                            type: TextInputType.number,
                            validator: _optionalPositiveNumber)),
                  ]),
                  const SizedBox(height: 16),
                  TranslatedText('Meal type',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _mealOptions.map((mt) {
                      final selected = _selectedMeal == mt;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => _selectedMeal = mt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.primary
                                : colors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TranslatedText(mt,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : colors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TranslatedText(_error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // disable while saving to prevent double-tap
                      onPressed: _saving ? null : _addEntry,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const TranslatedText('Add Entry',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Build Method
  // PURPOSE: Renders the complete Calorie Tracker UI. The layout is:
  //          1. Header row with title and add button (floating action style)
  //          2. Summary card with gradient background showing:
  //             - Calories consumed vs remaining
  //             - Circular progress indicator for daily goal
  //             - Linear progress bar
  //          3. Macro nutrient cards (Carbs, Protein, Fat) in a row
  //          4. "Today's Entries" header with item count
  //          5. Scrollable list of food entry tiles (or empty state)
  //          Uses Consumer<GlucoseProvider> to reactively rebuild when
  //          foodLogs change in the provider.
  // ═══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        final entries = provider.foodLogs;
        final total = _total(entries);
        final progress = _progress(entries);
        final remaining = _dailyGoal - total;

        return SafeArea(
          child: Column(
            children: [
              // ═══════════════════════════════════════════════════════════════════════════════
              // WIDGET: Header
              // PURPOSE: Screen title "Calorie Tracker" with a circular add button
              //          that opens the _showAddSheet bottom sheet when tapped.
              // ═══════════════════════════════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TranslatedText('Calorie Tracker',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary)),
                    GestureDetector(
                      onTap: () => _showAddSheet(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: provider.loadFoodLogs,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ═══════════════════════════════════════════════════════════════════════════════
                              // WIDGET: Summary Card
                              // PURPOSE: A gradient card showing calorie tracking summary:
                              //          - Left: "Consumed" calories count
                              //          - Center: Circular progress indicator showing % of daily goal
                              //          - Right: "Remaining" calories
                              //          - Bottom: Linear progress bar + daily goal text
                              //          The gradient uses primary to primaryDark for visual depth.
                              // ═══════════════════════════════════════════════════════════════════════════════
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                        colors.primary,
                                        colors.primaryDark
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _chip('Consumed', '$total',
                                            'kcal', colors),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              height: 80,
                                              child:
                                                  CircularProgressIndicator(
                                                value: progress,
                                                strokeWidth: 7,
                                                backgroundColor: Colors
                                                    .white
                                                    .withValues(alpha: 0.3),
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                        Colors.white),
                                              ),
                                            ),
                                            Column(children: [
                                              Text(
                                                  '${(progress * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              Text('of goal',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.75),
                                                      fontSize: 10)),
                                            ]),
                                          ],
                                        ),
                                        _chip(
                                            'Remaining',
                                            remaining > 0
                                                ? '$remaining'
                                                : '0',
                                            'kcal',
                                            colors),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.25),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TranslatedText(
                                        'Daily goal: $_dailyGoal kcal',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ═══════════════════════════════════════════════════════════════════════════════
                              // WIDGET: Macro Nutrient Cards
                              // PURPOSE: Three colored cards showing total intake of:
                              //          - Carbs (amber/orange background)
                              //          - Protein (green background)
                              //          - Fat (blue background)
                              //          Each card shows an emoji icon, total grams, and label.
                              //          They expand equally using Expanded widgets in a Row.
                              // ═══════════════════════════════════════════════════════════════════════════════
                              Row(children: [
                                _macro(
                                    '🍞',
                                    'Carbs',
                                    '${_totalCarbs(entries).toStringAsFixed(1)}g',
                                    const Color(0xFFD4890A),
                                    colors),
                                const SizedBox(width: 10),
                                _macro(
                                    '🥩',
                                    'Protein',
                                    '${_totalProtein(entries).toStringAsFixed(1)}g',
                                    const Color(0xFF2E7D32),
                                    colors),
                                const SizedBox(width: 10),
                                _macro(
                                    '🥑',
                                    'Fat',
                                    '${_totalFat(entries).toStringAsFixed(1)}g',
                                    const Color(0xFF1565C0),
                                    colors),
                              ]),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TranslatedText("Today's Entries",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary)),
                                  TranslatedText('${entries.length} items',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary)),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // ═══════════════════════════════════════════════════════════════════════════════
                              // SECTION: Entries List
                              // PURPOSE: Shows either:
                              //          1. An empty state with icon and helper text when no entries exist
                              //          2. A list of _tile widgets for each food entry
                              //          The Dismissible wrapper on each tile enables swipe-to-delete.
                              // ═══════════════════════════════════════════════════════════════════════════════
                              if (entries.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 40),
                                    child: Column(children: [
                                      Icon(Icons.no_food_rounded,
                                          size: 48,
                                          color: colors.textSecondary),
                                      const SizedBox(height: 12),
                                      TranslatedText(
                                          'No entries yet.\nTap + to add your first meal.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: colors.textSecondary)),
                                    ]),
                                  ),
                                )
                              else
                                // Dismissible tiles with edit + undo
                                ...entries.map((e) => _tile(context, e)),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Reusable Widgets
  // PURPOSE: Helper methods that build commonly used UI components with consistent
  //          styling. Keeping these as private methods reduces code duplication
  //          and makes the build method more readable.
  // ═══════════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════════
  // WIDGET: _field()
  // PURPOSE: A styled TextFormField with consistent theming:
  //          - prefixIcon with the specified icon and primary color
  //          - Rounded corners (borderRadius: 12)
  //          - Filled background matching the theme
  //          - Focused and error border states
  //          - autovalidateMode: onUserInteraction for immediate feedback
  //          The validator parameter is passed directly to TextFormField.
  // ═══════════════════════════════════════════════════════════════════════════════
  Widget _field(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 13, color: colors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        filled: true,
        fillColor: colors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        errorStyle: const TextStyle(height: 0.8, fontSize: 11),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // WIDGET: _chip()
  // PURPOSE: A small vertical label-value-unit display used inside the summary card.
  //          Shows "Consumed"/"Remaining" labels with their calorie counts.
  //          The text is white to contrast against the gradient background.
  // ═══════════════════════════════════════════════════════════════════════════════
  Widget _chip(String label, String value, String unit,
          GlucoraColors colors) =>
      Column(children: [
        TranslatedText(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(unit,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75))),
      ]);

  // ═══════════════════════════════════════════════════════════════════════════════
  // WIDGET: _macro()
  // PURPOSE: A colored card for displaying a single macro nutrient total.
  //          Parameters:
  //          - emoji: visual icon (🍞, 🥩, 🥑)
  //          - label: nutrient name (Carbs, Protein, Fat)
  //          - value: formatted gram amount
  //          - bg: background color (different for each macro)
  //          Uses Expanded so all three macros share equal width in the Row.
  // ═══════════════════════════════════════════════════════════════════════════════
  Widget _macro(String emoji, String label, String value, Color bg,
          GlucoraColors colors) =>
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            TranslatedText(emoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            TranslatedText(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════════
  // WIDGET: _tile()
  // PURPOSE: A card representing a single food entry in the list. Features:
  //          - Leading icon based on meal type (breakfast, lunch, dinner, snack)
  //          - Food name, macro summary, and timestamp
  //          - Calorie count on the right
  //          - Edit button (pencil icon) that opens the edit sheet
  //          - Wrapped in Dismissible for swipe-to-delete from right to left
  //          The mealIcon switch statement maps meal types to appropriate icons.
  // ═══════════════════════════════════════════════════════════════════════════════
  Widget _tile(BuildContext context, FoodEntry e) {
    final colors = context.colors;

    IconData mealIcon;
    switch (e.mealType?.toLowerCase()) {
      case 'breakfast':
        mealIcon = Icons.free_breakfast_rounded;
        break;
      case 'lunch':
        mealIcon = Icons.lunch_dining_rounded;
        break;
      case 'dinner':
        mealIcon = Icons.dinner_dining_rounded;
        break;
      default:
        mealIcon = Icons.restaurant_rounded;
    }

    return Dismissible(
      key: ValueKey(e.id ?? e.name + e.loggedAt.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => _deleteEntry(context, e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colors.textSecondary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(mealIcon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(e.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                const SizedBox(height: 2),
                TranslatedText(
                  [
                    if (e.mealType != null) e.mealType!,
                    if (e.carbsG != null)
                      'C: ${e.carbsG!.toStringAsFixed(0)}g',
                    if (e.proteinG != null)
                      'P: ${e.proteinG!.toStringAsFixed(0)}g',
                    if (e.fatG != null)
                      'F: ${e.fatG!.toStringAsFixed(0)}g',
                  ].join(' · '),
                  style: TextStyle(
                      fontSize: 11, color: colors.textSecondary),
                ),
                const SizedBox(height: 2),
                TranslatedText(_formatTime(e.loggedAt),
                    style: TextStyle(
                        fontSize: 10, color: colors.textSecondary)),
              ],
            ),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TranslatedText('${e.calories}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary)),
                const TranslatedText('kcal',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF888888))),
              ]),
          const SizedBox(width: 4),
          // Edit button
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 18, color: colors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditSheet(context, e),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _formatTime()
  // PURPOSE: Formats a DateTime into 12-hour format with AM/PM (e.g., "2:30 PM").
  //          Handles midnight (0 → 12) and noon correctly.
  // ═══════════════════════════════════════════════════════════════════════════════
  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final l = dt.toLocal();
    final h = l.hour > 12 ? l.hour - 12 : l.hour == 0 ? 12 : l.hour;
    final m = l.minute.toString().padLeft(2, '0');
    final period = l.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}