import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/models/glucose_log_model.dart';
import 'package:glucora_ai_companion/providers/patient_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualLogScreen extends ConsumerStatefulWidget {
  const ManualLogScreen({super.key});

  @override
  ConsumerState<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends ConsumerState<ManualLogScreen> {
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _mealTime = 'Before Meal';
  String _unit = 'mg/dL';
  bool _saving = false;
  String? _error;

  String? _newlyAddedId;

  static const _mealOptions = [
    'Before Meal',
    'After Meal',
    'Fasting',
    'Bedtime',
    'Other',
  ];

  static const double _minMgDl = 20;
  static const double _maxMgDl = 600;
  static const double _minMmol = 1.1;
  static const double _maxMmol = 33.3;
  static const double _lowMgDl = 70;
  static const double _highMgDl = 180;

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await ref.read(glucoseProvider.notifier).init(user.id);
    }
  }

  String? _validateGlucose(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a value';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Must be a number';

    if (_unit == 'mg/dL') {
      if (n < _minMgDl) return 'Too low — minimum is ${_minMgDl.toInt()} mg/dL';
      if (n > _maxMgDl) return 'Too high — maximum is ${_maxMgDl.toInt()} mg/dL';
    } else {
      if (n < _minMmol) return 'Too low — minimum is $_minMmol mmol/L';
      if (n > _maxMmol) return 'Too high — maximum is $_maxMmol mmol/L';
    }
    return null;
  }

  double _toMgDl(double value) => _unit == 'mmol/L' ? value * 18.0182 : value;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final val = _glucoseCtrl.text.trim();
    final error = _validateGlucose(val);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_saving) return;

    final parsed = double.parse(val);
    final valueInMgDl = _toMgDl(parsed);
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(glucoseProvider.notifier).insertLog(valueInMgDl, notes, _mealTime);

      final newId = ref.read(glucoseProvider).logs.isNotEmpty
          ? ref.read(glucoseProvider).logs.first.id
          : null;

      _glucoseCtrl.clear();
      _notesCtrl.clear();

      if (mounted) {
        setState(() => _newlyAddedId = newId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Reading saved — ${parsed.toStringAsFixed(_unit == 'mmol/L' ? 1 : 0)} $_unit',
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _newlyAddedId = null);
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLog(BuildContext ctx, GlucoseLog log) async {
    await ref.read(glucoseProvider.notifier).deleteLog(log.id);

    if (mounted && _newlyAddedId == log.id) {
      setState(() => _newlyAddedId = null);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('${log.value.toStringAsFixed(0)} mg/dL reading deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ref.read(glucoseProvider.notifier).insertLog(
              log.value,
              log.notes,
              log.mealTime ?? 'Before Meal',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = ref.watch(glucoseProvider);

    final sortedLogs = [...provider.logs]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

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
                  const SizedBox(height: 4),
                  TranslatedText(
                    _unit == 'mg/dL'
                        ? 'T1D target: 70–180 mg/dL  •  safe range: 20–600'
                        : 'T1D target: 3.9–10.0 mmol/L  •  safe range: 1.1–33.3',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          context,
                          _glucoseCtrl,
                          'Glucose value',
                          Icons.water_drop_rounded,
                          type: const TextInputType.numberWithOptions(
                              decimal: true),
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
                            items: ['mg/dL', 'mmol/L']
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: TranslatedText(u),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _unit = v!;
                                _error = null;
                                if (_glucoseCtrl.text.isNotEmpty) {
                                  _error = _validateGlucose(_glucoseCtrl.text);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 13, color: colors.error),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                  color: colors.error, fontSize: 12),
                            ),
                          ),
                        ],
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
                              onTap: () => setState(() => _mealTime = mt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _mealTime == mt
                                      ? colors.primary
                                      : colors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _mealTime == mt
                                        ? colors.primary
                                        : colors.textSecondary
                                            .withValues(alpha: 0.15),
                                  ),
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
              ],
            ),
            const SizedBox(height: 12),

            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (sortedLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: TranslatedText(
                    'No logs yet.\\nEnter a reading above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: colors.textSecondary),
                  ),
                ),
              )
            else
              ...sortedLogs.map(
                (log) => _logTile(context, log,
                    isNew: log.id == _newlyAddedId),
              ),

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
      onChanged: (_) {
        if (_error != null) setState(() => _error = _validateGlucose(ctrl.text));
      },
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: colors.textSecondary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _logTile(BuildContext context, GlucoseLog log,
      {bool isNew = false}) {
    final colors = context.colors;
    final mgDl = log.value;

    final Color statusColor;
    final String statusLabel;
    if (mgDl < _lowMgDl) {
      statusColor = const Color(0xFF2563EB);
      statusLabel = 'Low';
    } else if (mgDl > _highMgDl) {
      statusColor = const Color(0xFFDC2626);
      statusLabel = 'High';
    } else {
      statusColor = const Color(0xFF16A34A);
      statusLabel = 'In range';
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isNew
              ? colors.primary.withValues(alpha: 0.06)
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNew
                ? colors.primary.withValues(alpha: 0.4)
                : colors.textSecondary.withValues(alpha: 0.12),
            width: isNew ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 54,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TranslatedText(
                        '${mgDl.toStringAsFixed(0)} mg/dL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TranslatedText(
                        '(${(mgDl / 18.0182).toStringAsFixed(1)} mmol/L)',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (log.mealTime != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
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
                            fontSize: 11, color: colors.textSecondary),
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