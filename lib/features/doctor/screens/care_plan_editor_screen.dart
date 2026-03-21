import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'care_plan.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
// ─── SCREEN ──────────────────────────────────────────────────────────────────

class CarePlanEditorScreen extends StatefulWidget {
  final String patientName;
  final CarePlan? existingPlan;

  const CarePlanEditorScreen({
    super.key,
    required this.patientName,
    this.existingPlan,
  });

  @override
  State<CarePlanEditorScreen> createState() => _CarePlanEditorScreenState();
}

class _CarePlanEditorScreenState extends State<CarePlanEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late CarePlan _plan;

  // Controllers
  late TextEditingController _targetMinCtrl;
  late TextEditingController _targetMaxCtrl;
  late TextEditingController _icrCtrl;
  late TextEditingController _isfCtrl;
  late TextEditingController _maxBolusCtrl;
  late TextEditingController _notesCtrl;

  final List<String> _insulinTypes = [
    'NovoLog (Fast-Acting)',
    'Humalog (Fast-Acting)',
    'Apidra (Fast-Acting)',
    'Fiasp (Ultra Fast-Acting)',
    'Tresiba (Long-Acting)',
    'Lantus (Long-Acting)',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _plan =
        widget.existingPlan ??
        CarePlan(nextAppointment: DateTime.now().add(const Duration(days: 30)));

    _targetMinCtrl = TextEditingController(
      text: _plan.targetGlucoseMin.toString(),
    );
    _targetMaxCtrl = TextEditingController(
      text: _plan.targetGlucoseMax.toString(),
    );
    _icrCtrl = TextEditingController(text: _plan.insulinToCarbRatio.toString());
    _isfCtrl = TextEditingController(text: _plan.sensitivityFactor.toString());
    _maxBolusCtrl = TextEditingController(text: _plan.maxAutoBolus.toString());
    _notesCtrl = TextEditingController(text: _plan.doctorNotes);
  }

  @override
  void dispose() {
    _targetMinCtrl.dispose();
    _targetMaxCtrl.dispose();
    _icrCtrl.dispose();
    _isfCtrl.dispose();
    _maxBolusCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final colors = context.colors;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    _plan.targetGlucoseMin = int.tryParse(_targetMinCtrl.text) ?? 70;
    _plan.targetGlucoseMax = int.tryParse(_targetMaxCtrl.text) ?? 180;
    _plan.insulinToCarbRatio = double.tryParse(_icrCtrl.text) ?? 12;
    _plan.sensitivityFactor = double.tryParse(_isfCtrl.text) ?? 45;
    _plan.maxAutoBolus = double.tryParse(_maxBolusCtrl.text) ?? 4.0;
    _plan.doctorNotes = _notesCtrl.text.trim();

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Care plan saved successfully',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, _plan);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _patientChip(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.track_changes_outlined, 'Target Glucose Range'),
              const SizedBox(height: 12),
              _buildTargetRangeCard(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.water_drop_outlined, 'Insulin Type'),
              const SizedBox(height: 12),
              _buildInsulinTypeCard(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.schedule_outlined, 'Basal Program'),
              const SizedBox(height: 12),
              _buildBasalProgramCard(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.calculate_outlined, 'Dosing Ratios'),
              const SizedBox(height: 12),
              _buildDosingRatiosCard(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.bolt_outlined, 'AID Limits'),
              const SizedBox(height: 12),
              _buildAIDLimitsCard(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.calendar_today_outlined, 'Next Appointment'),
              const SizedBox(height: 12),
              _buildAppointmentCard(context),
              const SizedBox(height: 28),

              _sectionHeader(context, Icons.notes_outlined, 'Doctor Notes'),
              const SizedBox(height: 12),
              _buildNotesCard(context),
              const SizedBox(height: 36),

              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Care Plan Editor',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            'Tap any field to edit',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientChip(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, color: colors.primaryDark, size: 16),
          const SizedBox(width: 8),
          Text(
            'Editing plan for ${widget.patientName}',
            style: TextStyle(
              color: colors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetRangeCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  context,
                  label: 'Minimum',
                  unit: 'mg/dL',
                  controller: _targetMinCtrl,
                  hint: '70',
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Required';
                    if (n < 54 || n > 100) return '54–100';
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 20,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _labeledField(
                  context,
                  label: 'Maximum',
                  unit: 'mg/dL',
                  controller: _targetMaxCtrl,
                  hint: '180',
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Required';
                    if (n < 120 || n > 250) return '120–250';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommended range: 70–180 mg/dL for most Type 1 patients.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsulinTypeCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: DropdownButtonFormField<String>(
        initialValue: _plan.insulinType,
        decoration: InputDecoration(
          labelText: 'Insulin Type',
          labelStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
          filled: true,
          fillColor: colors.surface,
        ),
        items: _insulinTypes
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _plan.insulinType = val!),
      ),
    );
  }

  Widget _buildBasalProgramCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        children: [
          ...List.generate(_plan.basalProgram.length, (i) {
            final seg = _plan.basalProgram[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _basalSegmentRow(context, seg, i),
            );
          }),
          const Divider(height: 8),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _plan.basalProgram.add(
                  BasalSegment(startHour: 0, endHour: 6, rate: 0.8),
                );
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colors.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add Segment',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _basalSegmentRow(BuildContext context, BasalSegment seg, int index) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Segment ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_plan.basalProgram.length > 1)
                GestureDetector(
                  onTap: () =>
                      setState(() => _plan.basalProgram.removeAt(index)),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timePickerField(
                  context,
                  label: 'Start',
                  hour: seg.startHour,
                  onChanged: (h) => setState(() => seg.startHour = h),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timePickerField(
                  context,
                  label: 'End',
                  hour: seg.endHour,
                  onChanged: (h) => setState(() => seg.endHour = h),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numericField(
                  context,
                  label: 'Rate',
                  unit: 'U/h',
                  initialValue: seg.rate.toString(),
                  onChanged: (v) {
                    final d = double.tryParse(v);
                    if (d != null) seg.rate = d;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timePickerField(
    BuildContext context, {
    required String label,
    required int hour,
    required void Function(int) onChanged,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 12, color: colors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numericField(
    BuildContext context, {
    required String label,
    required String unit,
    required String initialValue,
    required void Function(String) onChanged,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: colors.textSecondary)),
          TextFormField(
            initialValue: initialValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffix: Text(
                unit,
                style: TextStyle(fontSize: 10, color: colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosingRatiosCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        children: [
          _labeledField(
            context,
            label: 'Insulin-to-Carb Ratio (ICR)',
            unit: 'g carbs per 1 U',
            controller: _icrCtrl,
            hint: '12',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Enter a valid number';
              return null;
            },
            helperText: 'e.g. 12 means 1 U covers 12g of carbs',
          ),
          const SizedBox(height: 16),
          _labeledField(
            context,
            label: 'Insulin Sensitivity Factor (ISF)',
            unit: 'mg/dL per 1 U',
            controller: _isfCtrl,
            hint: '45',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Enter a valid number';
              return null;
            },
            helperText: 'e.g. 45 means 1 U drops glucose by 45 mg/dL',
          ),
        ],
      ),
    );
  }

  Widget _buildAIDLimitsCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        children: [
          _labeledField(
            context,
            label: 'Maximum Auto-Bolus',
            unit: 'units per event',
            controller: _maxBolusCtrl,
            hint: '4.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Enter a valid number';
              if (n > 10) return 'Max 10 U for safety';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: colors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The AID system will never deliver more than this in a single automated correction.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context) {
    final colors = context.colors;
    final date = _plan.nextAppointment;
    return _card(
      context,
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.light(
                  primary: colors.accent,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            setState(() => _plan.nextAppointment = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: colors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Appointment',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : 'Tap to select a date',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: date != null
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: TextFormField(
        controller: _notesCtrl,
        maxLines: 5,
        minLines: 4,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontSize: 14, height: 1.5, color: colors.textPrimary),
        decoration: InputDecoration(
          hintText:
              'Add instructions, reminders, or observations for this patient...',
          hintStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
          filled: true,
          fillColor: colors.surface,
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Save Care Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
    String? helperText,
    TextInputType keyboardType = TextInputType.number,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
        hintText: hint,
        suffixText: unit,
        suffixStyle: TextStyle(fontSize: 12, color: colors.textSecondary),
        helperText: helperText,
        helperStyle: TextStyle(fontSize: 11, color: colors.textSecondary),
        helperMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: colors.surface,
      ),
    );
  }
}