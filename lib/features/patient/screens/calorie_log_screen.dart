import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/services/translated_text.dart'; // ← Add this import

class CalorieLogScreen extends StatefulWidget {
  const CalorieLogScreen({super.key});

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends State<CalorieLogScreen> {
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  static const int _dailyGoal = 2000;
  String _selectedMeal = 'Snack';
  static const _mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  List<_FoodEntry> _entries = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // ════════════════════════════════════════════════════
  // COMPUTED
  // ════════════════════════════════════════════════════
  int get _total => _entries.fold(0, (s, e) => s + e.calories);
  double get _progress => (_total / _dailyGoal).clamp(0.0, 1.0);
  double get _totalCarbs => _entries.fold(0.0, (s, e) => s + (e.carbsG ?? 0));
  double get _totalProtein =>
      _entries.fold(0.0, (s, e) => s + (e.proteinG ?? 0));
  double get _totalFat => _entries.fold(0.0, (s, e) => s + (e.fatG ?? 0));

  // ════════════════════════════════════════════════════
  // FETCH
  // ════════════════════════════════════════════════════
  Future<void> _loadLogs() async {
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final patientId = await getPatientProfileId(userId);
      if (patientId == null) throw Exception('No patient profile');

      // Only fetch today's logs
      final startOfDay = DateTime.now().toLocal();
      final from = DateTime(startOfDay.year, startOfDay.month, startOfDay.day)
          .toUtc()
          .toIso8601String();

      final response = await supabase
          .from('food_logs')
          .select()
          .eq('patient_id', patientId)
          .gte('logged_at', from)
          .order('logged_at', ascending: false);

      setState(() {
        _entries = (response as List)
            .map((e) => _FoodEntry.fromJson(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Failed to load food logs: $e');
      setState(() { _loading = false; _error = 'Failed to load logs'; });
    }
  }

  // ════════════════════════════════════════════════════
  // INSERT
  // ════════════════════════════════════════════════════
  Future<void> _addEntry() async {
    final name = _nameController.text.trim();
    final cal = int.tryParse(_calController.text.trim());
    if (name.isEmpty || cal == null) return;

    final carbs = double.tryParse(_carbsController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    setState(() => _saving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final patientId = await getPatientProfileId(userId);
      if (patientId == null) throw Exception('No patient profile');

      await supabase.from('food_logs').insert({
        'patient_id': patientId,
        'name': name,
        'calories': cal,
        'carbs_g': ?carbs,
        'protein_g': ?protein,
        'fat_g': ?fat,
        'meal_type': _selectedMeal,
        'logged_at': DateTime.now().toIso8601String(),
      });

      _nameController.clear();
      _calController.clear();
      _carbsController.clear();
      _proteinController.clear();
      _fatController.clear();
      _selectedMeal = 'Snack';

      if (mounted) Navigator.pop(context);
      await _loadLogs();
    } catch (e) {
      if (kDebugMode) print('Failed to save food log: $e');
      setState(() { _saving = false; _error = 'Failed to save'; });
    }
  }

  // ════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════
  Future<void> _deleteEntry(int index) async {
    final entry = _entries[index];
    if (entry.id == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('food_logs').delete().eq('id', entry.id!);
      await _loadLogs();
    } catch (e) {
      if (kDebugMode) print('Failed to delete food log: $e');
    }
  }

  // ════════════════════════════════════════════════════
  // BOTTOM SHEET
  // ════════════════════════════════════════════════════
  void _showAddSheet(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                TranslatedText("Add Food Entry",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary)),
                const SizedBox(height: 20),

                // Name + Calories
                _field(context, _nameController, "Food name",
                    Icons.fastfood_rounded),
                const SizedBox(height: 12),
                _field(context, _calController, "Calories (kcal)",
                    Icons.local_fire_department_rounded,
                    type: TextInputType.number),
                const SizedBox(height: 12),

                // Macros row
                Row(children: [
                  Expanded(
                    child: _field(context, _carbsController, "Carbs (g)",
                        Icons.grain_rounded,
                        type: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(context, _proteinController, "Protein (g)",
                        Icons.fitness_center_rounded,
                        type: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(context, _fatController, "Fat (g)",
                        Icons.opacity_rounded,
                        type: TextInputType.number),
                  ),
                ]),
                const SizedBox(height: 16),

                // Meal type selector
                TranslatedText("Meal type",
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
                        : const TranslatedText("Add Entry",
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
    );
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = _dailyGoal - _total;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText("Calorie Tracker",
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Summary card ──
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
                                    _chip("Consumed", "$_total",
                                        "kcal", colors),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          height: 80,
                                          child:
                                              CircularProgressIndicator(
                                            value: _progress,
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
                                          TranslatedText(
                                              "${(_progress * 100).toStringAsFixed(0)}%",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 16)),
                                          TranslatedText("of goal",
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(
                                                          alpha: 0.75),
                                                  fontSize: 10)),
                                        ]),
                                      ],
                                    ),
                                    _chip(
                                        "Remaining",
                                        remaining > 0
                                            ? "$remaining"
                                            : "0",
                                        "kcal",
                                        colors),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.25),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TranslatedText("Daily goal: $_dailyGoal kcal",
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                        fontSize: 12)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Macros — now live from backend ──
                          Row(children: [
                            _macro("🍞", "Carbs",
                                "${_totalCarbs.toStringAsFixed(1)}g",
                                const Color.fromARGB(255, 230, 175, 93), colors),
                            const SizedBox(width: 10),
                            _macro("🥩", "Protein",
                                "${_totalProtein.toStringAsFixed(1)}g",
                                const Color.fromARGB(255, 88, 138, 90), colors),
                            const SizedBox(width: 10),
                            _macro("🥑", "Fat",
                                "${_totalFat.toStringAsFixed(1)}g",
                                const Color.fromARGB(255, 76, 137, 187), colors),
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
                              TranslatedText("${_entries.length} items",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary)),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (_entries.isEmpty)
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
                                      "No entries yet.\nTap + to add your first meal.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: colors.textSecondary)),
                                ]),
                              ),
                            )
                          else
                            ...List.generate(_entries.length,
                                (i) => _tile(context, _entries[i], i)),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════════════
  Widget _field(BuildContext context, TextEditingController ctrl,
      String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    final colors = context.colors;
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 13, color: colors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        filled: true,
        fillColor: colors.background,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }

  Widget _chip(String label, String value, String unit,
          GlucoraColors colors) =>
      Column(children: [
        TranslatedText(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75))),
        const SizedBox(height: 4),
        TranslatedText(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        TranslatedText(unit,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75))),
      ]);

  Widget _macro(String emoji, String label, String value, Color bg,
          GlucoraColors colors) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            TranslatedText(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            TranslatedText(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            TranslatedText(label,
                style: TextStyle(
                    fontSize: 11, color: colors.textSecondary)),
          ]),
        ),
      );

  Widget _tile(BuildContext context, _FoodEntry e, int i) {
    final colors = context.colors;

    // Meal icon
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

    return Container(
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
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TranslatedText("${e.calories}",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primary)),
          const TranslatedText("kcal",
              style: TextStyle(
                  fontSize: 10, color: Color(0xFF888888))),
        ]),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _deleteEntry(i),
          child: Icon(Icons.close_rounded,
              size: 18, color: colors.textSecondary),
        ),
      ]),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final l = dt.toLocal();
    final h = l.hour > 12 ? l.hour - 12 : l.hour == 0 ? 12 : l.hour;
    final m = l.minute.toString().padLeft(2, '0');
    final period = l.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

// ════════════════════════════════════════════════════
// MODEL
// ════════════════════════════════════════════════════
class _FoodEntry {
  final int? id;
  final String name;
  final int calories;
  final double? carbsG;
  final double? proteinG;
  final double? fatG;
  final String? mealType;
  final DateTime? loggedAt;

  const _FoodEntry({
    this.id,
    required this.name,
    required this.calories,
    this.carbsG,
    this.proteinG,
    this.fatG,
    this.mealType,
    this.loggedAt,
  });

  factory _FoodEntry.fromJson(Map<String, dynamic> json) {
    return _FoodEntry(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      calories: json['calories'] as int,
      carbsG: json['carbs_g'] != null
          ? double.tryParse(json['carbs_g'].toString())
          : null,
      proteinG: json['protein_g'] != null
          ? double.tryParse(json['protein_g'].toString())
          : null,
      fatG: json['fat_g'] != null
          ? double.tryParse(json['fat_g'].toString())
          : null,
      mealType: json['meal_type'],
      loggedAt: json['logged_at'] != null
          ? DateTime.tryParse(json['logged_at'])
          : null,
    );
  }
}