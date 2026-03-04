import 'package:flutter/material.dart';

// Class name must be exactly: ManualLogScreen
// No Scaffold, no BottomNavigationBar — HomeScreen owns those.
class ManualLogScreen extends StatefulWidget {
  const ManualLogScreen({super.key});

  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _mealTime = "Before Meal";
  String _unit = "mg/dL";

  static const _mealOptions = [
    "Before Meal",
    "After Meal",
    "Fasting",
    "Bedtime",
    "Other",
  ];

  final List<_GlucoseLog> _logs = [
    _GlucoseLog("108 mg/dL", "Before Meal", "8:00 AM", "Fasting morning"),
    _GlucoseLog("142 mg/dL", "After Meal", "2:30 PM", "Post-lunch"),
  ];

  void _save() {
    final val = _glucoseCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _logs.insert(
          0,
          _GlucoseLog(
            "$val $_unit",
            _mealTime,
            TimeOfDay.now().format(context),
            _notesCtrl.text.trim().isEmpty
                ? "—"
                : _notesCtrl.text.trim(),
          ));
      _glucoseCtrl.clear();
      _notesCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Manual Log",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text("Log your glucose reading manually",
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),

            // Input card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: const Color(0xFFE8E8E8), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("New Reading",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 16),

                  // Value + unit
                  Row(children: [
                    Expanded(
                        child: _field(_glucoseCtrl, "Glucose value",
                            Icons.water_drop_rounded,
                            type: TextInputType.number)),
                    const SizedBox(width: 10),
                    Container(
                      height: 52,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w500),
                          items: ["mg/dL", "mmol/L"]
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _unit = v!),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),
                  const Text("Meal time",
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF888888))),
                  const SizedBox(height: 8),

                  // Meal time chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealOptions
                        .map((mt) => GestureDetector(
                              onTap: () =>
                                  setState(() => _mealTime = mt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _mealTime == mt
                                      ? const Color(0xFF199A8E)
                                      : const Color(0xFFF0F0F0),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(mt,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _mealTime == mt
                                            ? Colors.white
                                            : const Color(
                                                0xFF555555))),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),
                  _field(_notesCtrl, "Notes (optional)",
                      Icons.notes_rounded),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF199A8E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text("Save Reading",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Logs",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                Text("${_logs.length} entries",
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
              ],
            ),
            const SizedBox(height: 12),

            if (_logs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                      "No logs yet. Add your first reading above.",
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[400])),
                ),
              )
            else
              ...List.generate(
                  _logs.length, (i) => _logTile(_logs[i], i)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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

  Widget _logTile(_GlucoseLog log, int i) => Container(
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
            child: const Icon(Icons.water_drop_rounded,
                color: Color(0xFF199A8E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(log.value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text("${log.mealTime} · ${log.time}",
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888888))),
                if (log.notes != "—")
                  Text(log.notes,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA))),
              ])),
          GestureDetector(
              onTap: () => setState(() => _logs.removeAt(i)),
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey[400])),
        ]),
      );
}

class _GlucoseLog {
  final String value;
  final String mealTime;
  final String time;
  final String notes;
  const _GlucoseLog(this.value, this.mealTime, this.time, this.notes);
}