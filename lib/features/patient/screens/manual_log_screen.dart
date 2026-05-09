// lib\features\patient\screens\manual_log_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/models/glucose_log_model.dart';
import 'package:glucora_ai_companion/providers/glucose_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualLogScreen extends StatefulWidget {
  const ManualLogScreen({super.key});

  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _scrollController = ScrollController();
  String? _newlyAddedLogId;
  String _mealTime = "Before Meal";
  String _unit = "mg/dL";
  bool _saving = false;
  String? _error;

  static const _mealOptions = [
    "Before Meal",
    "After Meal",
    "Fasting",
    "Bedtime",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  // Dispose it properly
  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _notesCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final provider = context.read<GlucoseProvider>();
    if (provider.patientProfileId == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await provider.init(user.id);
    } else {
      await provider.loadLogs();
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final val = _glucoseCtrl.text.trim();

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
    final minVal = _unit == 'mmol/L' ? 1.1 : 20.0;
    final maxVal = _unit == 'mmol/L' ? 44.4 : 800.0;
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

    final valueInMgDl = _unit == 'mmol/L' ? parsed * 18.0182 : parsed;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final provider = context.read<GlucoseProvider>();
      await provider.insertLog(valueInMgDl, notes, _mealTime);
      _glucoseCtrl.clear();
      _notesCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reading saved: ${parsed.toStringAsFixed(1)} $_unit'),
            backgroundColor: Colors.green,
          ),
        );

        final updatedLogs = context.read<GlucoseProvider>().logs;
        if (updatedLogs.isNotEmpty) {
          setState(() => _newlyAddedLogId = updatedLogs.first.id);

          // Scroll down to show the recent logs section
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _scrollController.animateTo(
                400, // enough to get past the form
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
              );
            }
          });

          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) setState(() => _newlyAddedLogId = null);
          });
        }
      }
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteLog(GlucoseLog log) async {
    FocusManager.instance.primaryFocus?.unfocus(); // ← change this line
    await Future.delayed(const Duration(milliseconds: 100)); // ← add this
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
      // You'll need to add deleteLog to GlucoseProvider (see note below)
      await context.read<GlucoseProvider>().deleteLog(log.id);
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

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
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
                                color: colors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
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
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
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
                    Text(
                      "${provider.logs.length} entries",
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (provider.logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 48,
                            color: colors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No logs yet",
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your readings will appear here",
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      ...provider.logs.map(
                        (log) => KeyedSubtree(
                          key: ValueKey(log.id),
                          child: _logTile(context, log),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
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
                    Row(
                      children: [
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
                      log.source.name, // ← .name because source is now an enum
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

  String _formatDate(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return "${local.year}-"
        "${local.month.toString().padLeft(2, '0')}-"
        "${local.day.toString().padLeft(2, '0')} "
        "${local.hour.toString().padLeft(2, '0')}:"
        "${local.minute.toString().padLeft(2, '0')}";
  }
}
