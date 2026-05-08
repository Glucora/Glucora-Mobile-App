import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/notifications_service.dart';
import 'package:glucora_ai_companion/providers/glucose_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/models/medication_model.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _savingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _freqCtrl.dispose();
    _savingNotifier.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final provider = context.read<GlucoseProvider>();
    if (provider.patientProfileId == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await provider.init(user.id);
    } else {
      await provider.loadMedications();
    }
  }

  // ── Save medication ────────────────────────────────────────────────────────

  Future<void> _saveMedication(
    List<TimeOfDay> reminders,
    BuildContext sheetContext,
  ) async {
    if (_savingNotifier.value) return;
    FocusScope.of(sheetContext).unfocus();

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    _savingNotifier.value = true;

    try {
      final provider = context.read<GlucoseProvider>();

      final medId = await provider.insertMedication(
        name: name,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        frequency: int.tryParse(_freqCtrl.text.trim()),
      );

      if (medId == null) throw Exception('Failed to create medication');

      for (final time in reminders) {
        final hh = time.hour.toString().padLeft(2, '0');
        final mm = time.minute.toString().padLeft(2, '0');
        final remindAt = '$hh:$mm:00';

        final reminderId = await provider.insertMedicationReminder(
          medId: medId,
          remindAt: remindAt,
        );

        if (reminderId != null) {
          final notificationId = (medId * 1000) + reminderId;
          await NotificationService.scheduleReminder(
            id: notificationId,
            medName: name,
            remindAt: remindAt,
          );
        }
      }

      _nameCtrl.clear();
      _notesCtrl.clear();
      _freqCtrl.clear();

      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      await provider.loadMedications();
    } catch (e) {
      if (kDebugMode) print('SAVE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _savingNotifier.value = false;
    }
  }

  // ── Toggle ─────────────────────────────────────────────────────────────────

  Future<void> _toggleMedication(
      int medId, bool current, Medication med) async {
    final provider = context.read<GlucoseProvider>();
    if (current) {
      final reminders =
          await provider.getMedicationReminders(medId);
      final ids = reminders
          .map((r) => (medId * 1000) + (r['id'] as int))
          .toList();
      await NotificationService.cancelAll(ids);
    } else {
      for (final r in med.reminders) {
        await NotificationService.scheduleReminder(
          id: (med.id * 1000) + r.id,
          medName: med.name,
          remindAt: r.remindAt,
        );
      }
    }
    await provider.toggleMedication(medId, current);
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _deleteMedication(int medId) async {
    final provider = context.read<GlucoseProvider>();
    final reminders = await provider.getMedicationReminders(medId);
    final ids = reminders
        .map((r) => (medId * 1000) + (r['id'] as int))
        .toList();
    await NotificationService.cancelAll(ids);
    await provider.deleteMedication(medId);
  }

  // ── Add sheet ──────────────────────────────────────────────────────────────

  void _showAddSheet(BuildContext context) {
    final colors = context.colors;
    List<TimeOfDay> reminders = [];

    _nameCtrl.clear();
    _notesCtrl.clear();
    _freqCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: bottomInset + 24,
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
                        color: colors.textSecondary
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TranslatedText('Add Medication',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  const SizedBox(height: 20),
                  _field(ctx, _nameCtrl, 'Medication name',
                      Icons.medication_rounded),
                  const SizedBox(height: 12),
                  _field(ctx, _notesCtrl, 'Notes (optional)',
                      Icons.notes_rounded),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _freqCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: TextStyle(
                        fontSize: 14, color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Frequency (times/day)',
                      labelStyle: TextStyle(
                          fontSize: 13, color: colors.textSecondary),
                      prefixIcon: Icon(Icons.repeat_rounded,
                          size: 20, color: colors.primary),
                      filled: true,
                      fillColor: colors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: colors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TranslatedText('Reminders',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary)),
                      GestureDetector(
                        onTap: () async {
                          final currentFreq =
                              int.tryParse(_freqCtrl.text.trim()) ??
                                  0;
                          if (currentFreq <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Enter frequency first'),
                                  duration: Duration(seconds: 2)),
                            );
                            return;
                          }
                          if (reminders.length >= currentFreq) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Max $currentFreq reminder${currentFreq > 1 ? 's' : ''} for this frequency'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setSheet(() => reminders.add(picked));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_alarm_rounded,
                                  size: 14, color: colors.primary),
                              const SizedBox(width: 4),
                              Builder(builder: (context) {
                                final currentFreq = int.tryParse(
                                        _freqCtrl.text.trim()) ??
                                    0;
                                return Text(
                                  currentFreq > 0
                                      ? 'Add time (${reminders.length}/$currentFreq)'
                                      : 'Add time',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.primary),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (reminders.isEmpty)
                    TranslatedText('No reminders added yet',
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          reminders.asMap().entries.map((entry) {
                        final i = entry.key;
                        final t = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              TranslatedText(t.format(ctx),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setSheet(
                                    () => reminders.removeAt(i)),
                                child: const Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: _savingNotifier,
                    builder: (_, saving, _) => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () {
                                final currentFreq = int.tryParse(
                                        _freqCtrl.text.trim()) ??
                                    0;
                                if (currentFreq > 0 &&
                                    reminders.length != currentFreq) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Add $currentFreq reminder${currentFreq > 1 ? 's' : ''} to match frequency — you have ${reminders.length}'),
                                      backgroundColor: Colors.orange,
                                      duration:
                                          const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }
                                _saveMedication(reminders, ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Save Medication',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        final activeMeds =
            provider.medications.where((m) => m.isActive).toList();
        final inactiveMeds =
            provider.medications.where((m) => !m.isActive).toList();

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText('Medications',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary)),
                        Text('${activeMeds.length} active',
                            style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary)),
                      ],
                    ),
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
                    : provider.errorMessage != null
                        ? Center(
                            child: TranslatedText(
                              provider.errorMessage!,
                              style:
                                  const TextStyle(color: Colors.red),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadMedications,
                            child: SingleChildScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (provider.medications.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 80),
                                        child: Column(
                                          children: [
                                            Icon(
                                                Icons
                                                    .medication_liquid_rounded,
                                                size: 56,
                                                color:
                                                    colors.textSecondary),
                                            const SizedBox(height: 12),
                                            TranslatedText(
                                                'No medications yet.\nTap + to add one.',
                                                textAlign:
                                                    TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: colors
                                                        .textSecondary)),
                                          ],
                                        ),
                                      ),
                                    )
                                  else ...[
                                    if (activeMeds.isNotEmpty) ...[
                                      _sectionLabel('Active', colors),
                                      const SizedBox(height: 10),
                                      ...activeMeds.map((m) =>
                                          _medCard(context, m)),
                                    ],
                                    if (inactiveMeds.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      _sectionLabel(
                                          'Inactive', colors),
                                      const SizedBox(height: 10),
                                      ...inactiveMeds.map((m) =>
                                          _medCard(context, m)),
                                    ],
                                  ],
                                  const SizedBox(height: 30),
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

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label, GlucoraColors colors) =>
      TranslatedText(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary));

  Widget _medCard(BuildContext context, Medication med) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: med.isActive
              ? colors.primary.withValues(alpha: 0.2)
              : colors.textSecondary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: med.isActive
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication_rounded,
                      size: 22,
                      color: med.isActive
                          ? colors.primary
                          : colors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(med.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: med.isActive
                                  ? colors.textPrimary
                                  : colors.textSecondary)),
                      if (med.notes != null &&
                          med.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        TranslatedText(med.notes!,
                            style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                fontStyle: FontStyle.italic)),
                      ],
                      if (med.frequency != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.repeat_rounded,
                                size: 12,
                                color: colors.textSecondary),
                            const SizedBox(width: 4),
                            TranslatedText('${med.frequency}x per day',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: med.isActive,
                  activeThumbColor: colors.primary,
                  onChanged: (_) =>
                      _toggleMedication(med.id, med.isActive, med),
                ),
              ],
            ),
          ),
          if (med.reminders.isNotEmpty) ...[
            Divider(
                height: 1,
                thickness: 1,
                color: colors.textSecondary.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alarm_rounded,
                          size: 12, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      TranslatedText('Reminders',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: med.reminders
                        .map((r) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: med.isActive
                                    ? colors.primary
                                        .withValues(alpha: 0.1)
                                    : colors.textSecondary
                                        .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 11,
                                      color: med.isActive
                                          ? colors.primary
                                          : colors.textSecondary),
                                  const SizedBox(width: 4),
                                  TranslatedText(
                                      _formatTime(r.remindAt),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: med.isActive
                                              ? colors.primary
                                              : colors.textSecondary)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          Divider(
              height: 1,
              thickness: 1,
              color: colors.textSecondary.withValues(alpha: 0.1)),
          TextButton.icon(
            onPressed: () => _confirmDelete(context, med),
            icon: Icon(Icons.delete_outline_rounded,
                size: 16, color: colors.error),
            label: TranslatedText('Remove',
                style: TextStyle(fontSize: 13, color: colors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medication med) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: TranslatedText('Remove Medication',
            style: TextStyle(color: colors.textPrimary)),
        content: TranslatedText(
            'Are you sure you want to remove "${med.name}"?',
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TranslatedText('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMedication(med.id);
            },
            child: TranslatedText('Remove',
                style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

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

  String _formatTime(String remindAt) {
    try {
      final parts = remindAt.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12
          ? hour - 12
          : hour == 0
              ? 12
              : hour;
      return '$hour:$minute $period';
    } catch (_) {
      return remindAt;
    }
  }
}