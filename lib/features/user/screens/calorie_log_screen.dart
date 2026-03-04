import 'package:flutter/material.dart';

// Class name must be exactly: CalorieLogScreen
// No Scaffold, no BottomNavigationBar — HomeScreen owns those.
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

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text("Add Food Entry",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 20),
            _field(_nameController, "Food name", Icons.fastfood_rounded),
            const SizedBox(height: 12),
            _field(_calController, "Calories (kcal)",
                Icons.local_fire_department_rounded,
                type: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addEntry,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF199A8E),
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

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: Color(0xFF888888)),
        prefixIcon:
            Icon(icon, size: 20, color: const Color(0xFF199A8E)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF199A8E), width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _dailyGoal - _total;

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Calorie Tracker",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                GestureDetector(
                  onTap: _showAddSheet,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: const Color(0xFF199A8E),
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
                  // Summary gradient card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [
                            Color(0xFF199A8E),
                            Color(0xFF0D6E65)
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
                            _chip("Consumed", "$_total", "kcal"),
                            // Circle progress
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: _progress,
                                    strokeWidth: 7,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.25),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            Colors.white),
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
                                          color: Colors.white
                                              .withOpacity(0.75),
                                          fontSize: 10)),
                                ]),
                              ],
                            ),
                            _chip(
                                "Remaining",
                                remaining > 0 ? "$remaining" : "0",
                                "kcal"),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Daily goal: $_dailyGoal kcal",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Macro chips
                  Row(children: [
                    _macro("🍞", "Carbs", "142g",
                        const Color(0xFFFFF4E0)),
                    const SizedBox(width: 10),
                    _macro("🥩", "Protein", "68g",
                        const Color(0xFFE8F5E9)),
                    const SizedBox(width: 10),
                    _macro(
                        "🥑", "Fat", "34g", const Color(0xFFE3F2FD)),
                  ]),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Entries",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      Text("${_entries.length} items",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_entries.isEmpty)
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          Icon(Icons.no_food_rounded,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                              "No entries yet.\nTap + to add your first meal.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400])),
                        ]),
                      ),
                    )
                  else
                    ...List.generate(
                        _entries.length, (i) => _tile(_entries[i], i)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, String unit) => Column(children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.75))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(unit,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.75))),
      ]);

  Widget _macro(String emoji, String label, String value, Color bg) =>
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888))),
          ]),
        ),
      );

  Widget _tile(_FoodEntry e, int i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFF199A8E).withOpacity(0.10),
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
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text("${e.meal} · ${e.time}",
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888888))),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${e.calories}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF199A8E))),
            const Text("kcal",
                style:
                    TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => setState(() => _entries.removeAt(i)),
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey[400])),
        ]),
      );
}

class _FoodEntry {
  final String name;
  final int calories;
  final String meal;
  final String time;
  const _FoodEntry(this.name, this.calories, this.meal, this.time);
}