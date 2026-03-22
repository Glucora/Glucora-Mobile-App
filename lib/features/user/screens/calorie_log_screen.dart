import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

class CalorieLogScreen extends StatefulWidget {
  const CalorieLogScreen({super.key});

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends State<CalorieLogScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calController = TextEditingController();

  static const int _dailyGoal = 2000;

  final List<_FoodEntry> _entries = [
    _FoodEntry("Oatmeal with berries", 320, "Breakfast", "7:30 AM"),
    _FoodEntry("Grilled chicken salad", 450, "Lunch", "1:00 PM"),
  ];

  int get _total => _entries.fold(0, (s, e) => s + e.calories);
  double get _progress => (_total / _dailyGoal).clamp(0.0, 1.0);

  void _showAddSheet(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: colors.textSecondary,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text("Add Food Entry",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              const SizedBox(height: 20),
              _field(context, _nameController, "Food name", Icons.fastfood_rounded),
              const SizedBox(height: 12),
              _field(context, _calController, "Calories (kcal)",
                  Icons.local_fire_department_rounded,
                  type: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addEntry,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text("Add Entry",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addEntry() {
    final name = _nameController.text.trim();
    final cal = int.tryParse(_calController.text.trim());
    if (name.isEmpty || cal == null) return;
    setState(() {
      _entries.add(_FoodEntry(
          name, cal, "Snack", TimeOfDay.now().format(context)));
      _nameController.clear();
      _calController.clear();
    });
    Navigator.pop(context);
  }

  Widget _field(BuildContext context, TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    final colors = context.colors;
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = _dailyGoal - _total;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Calorie Tracker",
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [colors.primary, colors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _chip("Consumed", "$_total", "kcal", colors),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: _progress,
                                    strokeWidth: 7,
                                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                                Column(children: [
                                  Text(
                                      "${(_progress * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text("of goal",
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 10)),
                                ]),
                              ],
                            ),
                            _chip("Remaining", remaining > 0 ? "$remaining" : "0", "kcal", colors),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Daily goal: $_dailyGoal kcal",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(children: [
                    _macro("🍞", "Carbs", "142g", const Color(0xFFFFF4E0), colors),
                    const SizedBox(width: 10),
                    _macro("🥩", "Protein", "68g", const Color(0xFFE8F5E9), colors),
                    const SizedBox(width: 10),
                    _macro("🥑", "Fat", "34g", const Color(0xFFE3F2FD), colors),
                  ]),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Entries",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary)),
                      Text("${_entries.length} items",
                          style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_entries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          Icon(Icons.no_food_rounded,
                              size: 48, color: colors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                              "No entries yet.\nTap + to add your first meal.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                        ]),
                      ),
                    )
                  else
                    ...List.generate(
                        _entries.length, (i) => _tile(context, _entries[i], i)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, String unit, GlucoraColors colors) => Column(children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(unit,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
      ]);

  Widget _macro(String emoji, String label, String value, Color bg, GlucoraColors colors) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: colors.textSecondary)),
          ]),
        ),
      );

  Widget _tile(BuildContext context, _FoodEntry e, int i) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withValues(alpha:0.2)),
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
          child: const Icon(Icons.restaurant_rounded,
              color: Color(0xFF199A8E), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(e.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text("${e.meal} · ${e.time}",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("${e.calories}",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.primary)),
          const Text("kcal",
              style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
        ]),
        const SizedBox(width: 8),
        GestureDetector(
            onTap: () => setState(() => _entries.removeAt(i)),
            child: Icon(Icons.close_rounded,
                size: 18, color: colors.textSecondary)),
      ]),
    );
  }
}

class _FoodEntry {
  final String name;
  final int calories;
  final String meal;
  final String time;
  const _FoodEntry(this.name, this.calories, this.meal, this.time);
}