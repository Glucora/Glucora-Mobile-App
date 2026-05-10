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
  String _mealTime = 'Before Meal';
  String _unit = 'mg/dL';
  bool _saving = false;
  String? _error;

  static const _mealOptions = [
    'Before Meal',
    'After Meal',
    'Fasting',
    'Bedtime',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _notesCtrl.dispose();
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

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateGlucose(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a value';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Must be a number';
    if (n <= 0) return 'Must be > 0';
    if (n > 600) return 'Value too high (max 600)';
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final val = _glucoseCtrl.text.trim();
    final error = _validateGlucose(val);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (_saving) return; // guard double-tap

    final parsed = double.parse(val);
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context
          .read<GlucoseProvider>()
          .insertLog(parsed, notes, _mealTime);
      _glucoseCtrl.clear();
      _notesCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reading saved'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete with undo ──────────────────────────────────────────────────────

  Future<void> _deleteLog(BuildContext ctx, GlucoseLog log) async {
    final provider = ctx.read<GlucoseProvider>();
    await provider.deleteLog(log.id);

    if (!mounted) return;

    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('${log.value} mg/dL reading deleted'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // ✅ Restore by re-inserting
            await provider.insertLog(
              log.value,
              log.notes,
              log.mealTime ?? 'Before Meal',
            );
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                TranslatedText(
                  'Manual Log',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                TranslatedText(
                  'Log your glucose reading manually',
                  style: TextStyle(
                      fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 20),

                // ── Input card ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.textSecondary.withValues(alpha: 0.2),
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
                        'New Reading',
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
                              'Glucose value',
                              Icons.water_drop_rounded,
                              type: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.textSecondary
                                    .withValues(alpha: 0.2),
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
                                items: ['mg/dL', 'mmol/L']
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: TranslatedText(u),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _unit = v!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✅ Inline validation error
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 12),
                      TranslatedText(
                        'Meal time',
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
                            .map((mt) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _mealTime = mt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _mealTime == mt
                                          ? colors.primary
                                          : colors.background,
                                      borderRadius:
                                          BorderRadius.circular(20),
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
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 12),
                      _field(
                        context,
                        _notesCtrl,
                        'Notes (optional)',
                        Icons.notes_rounded,
                      ),
                      const SizedBox(height: 16),

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
                                  'Save Reading',
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

                // ── Recent logs ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TranslatedText(
                      'Recent Logs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    TranslatedText(
                      '${provider.logs.length} entries',
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
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: TranslatedText(
                        'No logs yet.\nEnter a reading above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: colors.textSecondary),
                      ),
                    ),
                  )
                else
                  // ✅ Dismissible tiles with undo
                  ...provider.logs
                      .map((log) => _logTile(context, log)),

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
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 13, color: colors.textSecondary),
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

  // ✅ Dismissible log tile with swipe-to-delete + undo
  Widget _logTile(BuildContext context, GlucoseLog log) {
    final colors = context.colors;

    IconData trendIcon;
    Color trendColor;
    switch (log.trend) {
      case GlucoseTrend.risingRapid:
      case GlucoseTrend.rising:
        trendIcon = Icons.arrow_upward_rounded;
        trendColor = Colors.red;
        break;
      case GlucoseTrend.fallingRapid:
      case GlucoseTrend.falling:
        trendIcon = Icons.arrow_downward_rounded;
        trendColor = Colors.blue;
        break;
      case GlucoseTrend.stable:
        trendIcon = Icons.remove_rounded;
        trendColor = Colors.green;
    }

    return Dismissible(
      key: ValueKey(log.id),
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
      onDismissed: (_) => _deleteLog(context, log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.water_drop_rounded,
                color: colors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TranslatedText(
                        '${log.value} mg/dL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Icon(trendIcon, color: trendColor, size: 20),
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
                        log.source.name,
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
                    style: TextStyle(
                        fontSize: 11, color: colors.textSecondary),
                  ),
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
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}