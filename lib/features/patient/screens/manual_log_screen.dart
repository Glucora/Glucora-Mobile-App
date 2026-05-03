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
  // Roaa
  String? _newlyAddedLogId;
  String _mealTime = "Before Meal";
  // Roaa
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

  // Roaa
  Future<void> _loadLogs() async {
    try {
      final data = await fetchGlucoseLogs();
      data.sort(
        (a, b) => b.recordedAt.compareTo(a.recordedAt),
      ); // ← newest first
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

  // Roaa
  Future<void> _save() async {
    final val = _glucoseCtrl.text.trim();

    // ── Validation with user feedback ──────────────────────────────────
    if (val.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a glucose value'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final parsed = double.tryParse(val);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ── Range validation ───────────────────────────────────────────────
    final minVal = _unit == 'mmol/L' ? 1.0 : 20.0;
    final maxVal = _unit == 'mmol/L' ? 55.0 : 1000.0;
    if (parsed < minVal || parsed > maxVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Value out of range for $_unit. Expected $minVal–$maxVal',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notes = _notesCtrl.text.trim().isEmpty
        ? null
        : _notesCtrl.text.trim();

    setState(() => _loading = true);

    try {
      await insertGlucoseLog(parsed, notes, _mealTime, _unit); // ← pass _unit
      _glucoseCtrl.clear();
      _notesCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading saved successfully ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadLogs();

      if (_logs.isNotEmpty && mounted) {
        setState(() => _newlyAddedLogId = _logs.first.id);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _newlyAddedLogId = null);
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Failed to save: $e";
      });
    }
  }

  // Roaa
  Future<void> _deleteLog(GlucoseLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reading'),
        content: Text(
          'Remove ${log.value.toStringAsFixed(1)} mg/dL logged at ${_formatDate(log.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await deleteGlucoseLog(log.id);
      setState(() => _loading = true);
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            TranslatedText(
              "Manual Log",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            TranslatedText(
              "Log your glucose reading manually",
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    "New Reading",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          context,
                          _glucoseCtrl,
                          "Glucose value",
                          Icons.water_drop_rounded,
                          type: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _unit,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            items: ["mg/dL", "mmol/L"]
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: TranslatedText(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _unit = v!),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  TranslatedText(
                    "Meal time",
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealOptions
                        .map(
                          (mt) => GestureDetector(
                            onTap: () => setState(() => _mealTime = mt),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _mealTime == mt
                                    ? colors.primary
                                    : colors.background,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TranslatedText(
                                mt,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _mealTime == mt
                                      ? Colors.white
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 12),
                  _field(
                    context,
                    _notesCtrl,
                    "Notes (optional)",
                    Icons.notes_rounded,
                  ),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TranslatedText(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : _save, // ✅ disable while loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const TranslatedText(
                              "Save Reading",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText(
                  "Recent Logs",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TranslatedText(
                  "${_logs.length} entries",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: TranslatedText(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
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

  Widget _field(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }

  // Roaa
  Widget _logTile(BuildContext context, GlucoseLog log) {
    final colors = context.colors;
    final isNew = log.id == _newlyAddedLogId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew ? colors.primary.withValues(alpha: 0.06) : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew
              ? colors.primary.withValues(alpha: 0.7)
              : colors.textSecondary.withValues(alpha: 0.15),
          width: isNew ? 1.8 : 1,
        ),
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
                      "${log.value.toStringAsFixed(1)} mg/dL",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteLog(log),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (log.mealTime != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TranslatedText(
                          log.mealTime!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TranslatedText(
                      log.source,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  _formatDate(log.recordedAt),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 13,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TranslatedText(
                          log.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
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

  // Roaa
  String _formatDate(DateTime dt) {
    // DateTime.parse() on an ISO string WITHOUT 'Z' is treated as local time.
    // Supabase returns UTC strings WITH 'Z', so we must call toLocal().
    // The fix: always parse as UTC explicitly, then convert to local.
    final local = dt.isUtc ? dt.toLocal() : dt;
    return "${local.year}-"
        "${local.month.toString().padLeft(2, '0')}-"
        "${local.day.toString().padLeft(2, '0')} "
        "${local.hour.toString().padLeft(2, '0')}:"
        "${local.minute.toString().padLeft(2, '0')}";
  }
}
