// lib\features\patient\screens\manual_log_screen.dart
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/models/glucose_log_model.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';

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

  List<GlucoseLog> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final data = await fetchGlucoseLogs();
      setState(() {
        _logs = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Failed to load data: $e";
      });
    }
  }
  
Future<void> _save() async {
  final val = _glucoseCtrl.text.trim();
  if (val.isEmpty) return;

  final parsed = double.tryParse(val);
  if (parsed == null) return;

  final notes = _notesCtrl.text.trim().isEmpty  // ✅ define notes BEFORE using it
      ? null
      : _notesCtrl.text.trim();

  setState(() => _loading = true);

  try {
    await insertGlucoseLog(parsed, notes, _mealTime);  // ✅ now notes is defined
    _glucoseCtrl.clear();
    _notesCtrl.clear();
    await _loadLogs();
  } catch (e) {
    setState(() {
      _loading = false;
      _error = "Failed to save: $e";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TranslatedText("Manual Log",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            const SizedBox(height: 4),
            TranslatedText("Log your glucose reading manually",
                style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.2),
                    width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText("New Reading",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                        child: _field(context, _glucoseCtrl, "Glucose value",
                            Icons.water_drop_rounded,
                            type: TextInputType.number)),
                    const SizedBox(width: 10),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.textSecondary
                                  .withValues(alpha: 0.2))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          style: TextStyle(
                              fontSize: 13,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500),
                          items: ["mg/dL", "mmol/L"]
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: TranslatedText(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),
                  TranslatedText("Meal time",
                      style:
                          TextStyle(fontSize: 12, color: colors.textSecondary)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealOptions
                        .map((mt) => GestureDetector(
                              onTap: () => setState(() => _mealTime = mt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _mealTime == mt
                                      ? colors.primary
                                      : colors.background,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TranslatedText(mt,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _mealTime == mt
                                            ? Colors.white
                                            : colors.textSecondary)),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),
                  _field(context, _notesCtrl, "Notes (optional)",
                      Icons.notes_rounded),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TranslatedText(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,    // ✅ disable while loading
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const TranslatedText("Save Reading",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText("Recent Logs",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary)),
                TranslatedText("${_logs.length} entries",
                    style: TextStyle(
                        fontSize: 12, color: colors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                  child: TranslatedText(_error!,
                      style: const TextStyle(color: Colors.red)))
            else if (_logs.isEmpty)
              const TranslatedText("No logs yet")
            else
              ..._logs.map((log) => _logTile(context, log)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController ctrl, String label,
      IconData icon,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }
Widget _logTile(BuildContext context, GlucoseLog log) {
  final colors = context.colors;

  IconData trendIcon;
  Color trendColor;
  switch (log.trend.toLowerCase()) {
    case 'up':
    case 'rising':
      trendIcon = Icons.arrow_upward_rounded;
      trendColor = Colors.red;
      break;
    case 'down':
    case 'falling':
      trendIcon = Icons.arrow_downward_rounded;
      trendColor = Colors.blue;
      break;
    default:
      trendIcon = Icons.remove_rounded;
      trendColor = Colors.green;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.15), width: 1),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.water_drop_rounded, color: colors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TranslatedText(
                    "${log.value} mg/dL",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary),
                  ),
                  Icon(trendIcon, color: trendColor, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Meal time badge
                  if (log.mealTime != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TranslatedText(
                        log.mealTime!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TranslatedText(
                    log.source,
                    style: TextStyle(
                        fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TranslatedText(
                _formatDate(log.recordedAt),
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              // Notes
              if (log.notes != null && log.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded,
                        size: 13, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TranslatedText(
                        log.notes!,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} "
        "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }
}
