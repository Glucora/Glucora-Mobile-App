import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'care_plan.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    _plan.targetGlucoseMin = int.tryParse(_targetMinCtrl.text) ?? 70;
    _plan.targetGlucoseMax = int.tryParse(_targetMaxCtrl.text) ?? 180;
    _plan.insulinToCarbRatio = double.tryParse(_icrCtrl.text) ?? 12;
    _plan.sensitivityFactor = double.tryParse(_isfCtrl.text) ?? 45;
    _plan.maxAutoBolus = double.tryParse(_maxBolusCtrl.text) ?? 4.0;
    _plan.doctorNotes = _notesCtrl.text.trim();

    // Simulate API save
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
        backgroundColor: const Color(0xFF2BB6A3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, _plan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _patientChip(),
              const SizedBox(height: 28),

              _sectionHeader(
                Icons.track_changes_outlined,
                'Target Glucose Range',
              ),
              const SizedBox(height: 12),
              _buildTargetRangeCard(),
              const SizedBox(height: 28),

              _sectionHeader(Icons.water_drop_outlined, 'Insulin Type'),
              const SizedBox(height: 12),
              _buildInsulinTypeCard(),
              const SizedBox(height: 28),

              _sectionHeader(Icons.schedule_outlined, 'Basal Program'),
              const SizedBox(height: 12),
              _buildBasalProgramCard(),
              const SizedBox(height: 28),

              _sectionHeader(Icons.calculate_outlined, 'Dosing Ratios'),
              const SizedBox(height: 12),
              _buildDosingRatiosCard(),
              const SizedBox(height: 28),

              _sectionHeader(Icons.bolt_outlined, 'AID Limits'),
              const SizedBox(height: 12),
              _buildAIDLimitsCard(),
              const SizedBox(height: 28),

              _sectionHeader(Icons.calendar_today_outlined, 'Next Appointment'),
              const SizedBox(height: 12),
              _buildAppointmentCard(),
              const SizedBox(height: 28),

              _sectionHeader(Icons.notes_outlined, 'Doctor Notes'),
              const SizedBox(height: 12),
              _buildNotesCard(),
              const SizedBox(height: 36),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A7A6E),
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

  // ─── PATIENT CHIP ──────────────────────────────────────────

  Widget _patientChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2BB6A3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2BB6A3).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, color: Color(0xFF1A7A6E), size: 16),
          const SizedBox(width: 8),
          Text(
            'Editing plan for ${widget.patientName}',
            style: const TextStyle(
              color: Color(0xFF1A7A6E),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A7A6E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A2B3C),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─── TARGET RANGE ──────────────────────────────────────────

  Widget _buildTargetRangeCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _labeledField(
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
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _labeledField(
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
              color: const Color(0xFF2BB6A3).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF2BB6A3)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommended range: 70–180 mg/dL for most Type 1 patients.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1A7A6E),
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

  // ─── INSULIN TYPE ──────────────────────────────────────────

  Widget _buildInsulinTypeCard() {
    return _card(
      child: DropdownButtonFormField<String>(
        initialValue: _plan.insulinType,
        decoration: InputDecoration(
          labelText: 'Insulin Type',
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2BB6A3), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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

  // ─── BASAL PROGRAM ─────────────────────────────────────────

  Widget _buildBasalProgramCard() {
    return _card(
      child: Column(
        children: [
          ...List.generate(_plan.basalProgram.length, (i) {
            final seg = _plan.basalProgram[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _basalSegmentRow(seg, i),
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
                  color: const Color(0xFF2BB6A3),
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Add Segment',
                  style: TextStyle(
                    color: Color(0xFF2BB6A3),
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

  Widget _basalSegmentRow(BasalSegment seg, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Segment ${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
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
                  label: 'Start',
                  hour: seg.startHour,
                  onChanged: (h) => setState(() => seg.startHour = h),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timePickerField(
                  label: 'End',
                  hour: seg.endHour,
                  onChanged: (h) => setState(() => seg.endHour = h),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numericField(
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

  Widget _timePickerField({
    required String label,
    required int hour,
    required void Function(int) onChanged,
  }) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numericField({
    required String label,
    required String unit,
    required String initialValue,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          TextFormField(
            initialValue: initialValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffix: Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DOSING RATIOS ─────────────────────────────────────────

  Widget _buildDosingRatiosCard() {
    return _card(
      child: Column(
        children: [
          _labeledField(
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

  // ─── AID LIMITS ────────────────────────────────────────────

  Widget _buildAIDLimitsCard() {
    return _card(
      child: Column(
        children: [
          _labeledField(
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
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Color(0xFFFF9F40),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The AID system will never deliver more than this in a single automated correction.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B6000),
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

  // ─── APPOINTMENT ───────────────────────────────────────────

  Widget _buildAppointmentCard() {
    final date = _plan.nextAppointment;
    return _card(
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF2BB6A3),
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
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF2BB6A3),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Appointment',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            ? const Color(0xFF1A2B3C)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NOTES ─────────────────────────────────────────────────

  Widget _buildNotesCard() {
    return _card(
      child: TextFormField(
        controller: _notesCtrl,
        maxLines: 5,
        minLines: 4,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 14, height: 1.5),
        decoration: InputDecoration(
          hintText:
              'Add instructions, reminders, or observations for this patient...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
            height: 1.5,
          ),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2BB6A3), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  // ─── SAVE BUTTON ───────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2BB6A3),
          disabledBackgroundColor: const Color(
            0xFF2BB6A3,
          ).withValues(alpha: 0.6),
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

  // ─── SHARED HELPERS ────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _labeledField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
    String? helperText,
    TextInputType keyboardType = TextInputType.number,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A2B3C),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        hintText: hint,
        suffixText: unit,
        suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        helperMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2BB6A3), width: 1.5),
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
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
