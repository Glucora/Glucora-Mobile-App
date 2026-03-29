import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/features/doctor/screens/care_plan.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientCarePlanScreen extends StatefulWidget {
  const PatientCarePlanScreen({super.key});

  @override
  State<PatientCarePlanScreen> createState() => _PatientCarePlanScreenState();
}

class _PatientCarePlanScreenState extends State<PatientCarePlanScreen> {
  CarePlan? _plan;
  String _doctorName = 'Your Doctor';
  String _lastUpdated = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCarePlan();
  }

  Future<void> _fetchCarePlan() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final patientProfileId = await getPatientProfileId(userId);
      if (patientProfileId == null) throw Exception('No patient profile found');

      final response = await supabase
          .from('care_plans')
          .select('*, doctor_profile(user_id, users(full_name))')
          .eq('patient_id', patientProfileId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _isLoading = false;
          _error = 'No care plan assigned yet.';
        });
        return;
      }

      List<BasalSegment> basalProgram = [];
      final rawBasal = response['basal_program'];
      if (rawBasal != null && rawBasal is List) {
        basalProgram = rawBasal
            .map(
              (seg) => BasalSegment(
                startHour: (seg['start_hour'] as num).toInt(),
                endHour: (seg['end_hour'] as num).toInt(),
                rate: (seg['rate'] as num).toDouble(),
              ),
            )
            .toList();
      }
      if (basalProgram.isEmpty) {
        basalProgram = [BasalSegment(startHour: 0, endHour: 24, rate: 0.9)];
      }

      final plan = CarePlan(
        targetGlucoseMin: response['target_glucose_min'] != null
            ? (response['target_glucose_min'] as num).toInt()
            : 70,
        targetGlucoseMax: response['target_glucose_max'] != null
            ? (response['target_glucose_max'] as num).toInt()
            : 180,
        insulinType: response['insulin_type'] ?? 'NovoLog (Fast-Acting)',
        basalProgram: basalProgram,
        insulinToCarbRatio: response['carb_ratio'] != null
            ? (response['carb_ratio'] as num).toDouble()
            : 12,
        sensitivityFactor: response['insulin_sensitivity_factor'] != null
            ? double.tryParse(
                    response['insulin_sensitivity_factor'].toString(),
                  ) ??
                  45
            : 45,
        maxAutoBolus: response['max_auto_dose_units'] != null
            ? (response['max_auto_dose_units'] as num).toDouble()
            : 4.0,
        doctorNotes: response['notes'] ?? '',
        nextAppointment: response['next_appointment'] != null
            ? DateTime.tryParse(response['next_appointment'])
            : null,
      );

      final doctorProfile = response['doctor_profile'];
      final doctorName = doctorProfile?['users']?['full_name'] ?? 'Your Doctor';

      final updatedAt = response['updated_at'];
      final lastUpdated = updatedAt != null
          ? _fmtDate(DateTime.tryParse(updatedAt)!)
          : '';

      setState(() {
        _plan = plan;
        _doctorName = doctorName;
        _lastUpdated = lastUpdated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading)
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );

    if (_error != null || _plan == null)
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: Text(_error ?? 'No care plan found.')),
      );

    final plan = _plan!;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Care Plan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Set by $_doctorName',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoChip(context),
            const SizedBox(height: 28),

            _sectionHeader(
              context,
              Icons.track_changes_outlined,
              'Target Glucose Range',
            ),
            const SizedBox(height: 12),
            _targetRangeCard(context, plan),
            const SizedBox(height: 28),

            _sectionHeader(
              context,
              Icons.water_drop_outlined,
              'Insulin & Basal Program',
            ),
            const SizedBox(height: 12),
            _insulinBasalCard(context, plan),
            const SizedBox(height: 28),

            _sectionHeader(context, Icons.calculate_outlined, 'Dosing Ratios'),
            const SizedBox(height: 12),
            _dosingRatiosCard(context, plan),
            const SizedBox(height: 28),

            _sectionHeader(context, Icons.bolt_outlined, 'AID Settings'),
            const SizedBox(height: 12),
            _aidSettingsCard(context, plan),
            const SizedBox(height: 28),

            _sectionHeader(
              context,
              Icons.calendar_today_outlined,
              'Next Appointment',
            ),
            const SizedBox(height: 12),
            _appointmentCard(context, plan),
            const SizedBox(height: 28),

            _sectionHeader(context, Icons.notes_outlined, 'Doctor Notes'),
            const SizedBox(height: 12),
            _notesCard(context, plan),

            const SizedBox(height: 16),
            _lastUpdatedFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF199A8E), size: 15),
          SizedBox(width: 8),
          Text(
            'Read-only — managed by your doctor',
            style: TextStyle(
              color: Color(0xFF199A8E),
              fontWeight: FontWeight.w600,
              fontSize: 12,
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
        Icon(icon, size: 18, color: colors.primary),
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

  Widget _targetRangeCard(BuildContext context, CarePlan plan) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlucoseRangeBar(
            min: plan.targetGlucoseMin,
            max: plan.targetGlucoseMax,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _rangeChip(
                context,
                label: 'Minimum',
                value: '${plan.targetGlucoseMin} mg/dL',
                color: colors.accent,
              ),
              const SizedBox(width: 12),
              _rangeChip(
                context,
                label: 'Maximum',
                value: '${plan.targetGlucoseMax} mg/dL',
                color: colors.warning,
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

  Widget _rangeChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insulinBasalCard(BuildContext context, CarePlan plan) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Insulin Type',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  plan.insulinType,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9B59B6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Basal Program',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...plan.basalProgram.asMap().entries.map(
            (e) => _basalSegmentRow(
              context,
              e.key,
              e.value,
              plan.basalProgram.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _basalSegmentRow(
    BuildContext context,
    int index,
    BasalSegment seg,
    int total,
  ) {
    final colors = context.colors;
    final isLast = index == total - 1;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_fmtHour(seg.startHour)} – ${_fmtHour(seg.endHour)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${seg.rate.toStringAsFixed(2)} U/h',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 6),
      ],
    );
  }

  Widget _dosingRatiosCard(BuildContext context, CarePlan plan) {
    final colors = context.colors;
    return _card(
      context,
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
              context,
              icon: Icons.restaurant_outlined,
              iconColor: const Color(0xFF5B8CF5),
              title: 'Insulin-to-Carb',
              value: plan.insulinToCarbRatio.toStringAsFixed(
                plan.insulinToCarbRatio % 1 == 0 ? 0 : 1,
              ),
              unit: 'g carbs / U',
              subtitle:
                  '1 U covers ${plan.insulinToCarbRatio.toStringAsFixed(0)}g carbs',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              context,
              icon: Icons.trending_down_outlined,
              iconColor: colors.warning,
              title: 'Sensitivity',
              value: plan.sensitivityFactor.toStringAsFixed(
                plan.sensitivityFactor % 1 == 0 ? 0 : 1,
              ),
              unit: 'mg/dL / U',
              subtitle:
                  '1 U drops glucose ${plan.sensitivityFactor.toStringAsFixed(0)} mg/dL',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aidSettingsCard(BuildContext context, CarePlan plan) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maximum Auto-Bolus',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.maxAutoBolus.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'U / event',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.bolt_outlined,
                  color: colors.warning,
                  size: 28,
                ),
              ),
            ],
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

  Widget _appointmentCard(BuildContext context, CarePlan plan) {
    final colors = context.colors;
    final date = plan.nextAppointment;
    final formatted = date != null ? _fmtDate(date) : 'Not scheduled';
    final daysUntil = date?.difference(DateTime.now()).inDays;

    return _card(
      context,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatted,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (daysUntil != null)
                  Text(
                    daysUntil > 0
                        ? 'In $daysUntil day${daysUntil == 1 ? '' : 's'}'
                        : daysUntil == 0
                        ? 'Today'
                        : '${-daysUntil} day${(-daysUntil) == 1 ? '' : 's'} ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysUntil >= 0 ? colors.primary : colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesCard(BuildContext context, CarePlan plan) {
    final colors = context.colors;
    if (plan.doctorNotes.trim().isEmpty) {
      return _card(
        context,
        child: Text(
          'No notes from your doctor.',
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return _card(
      context,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          plan.doctorNotes,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _lastUpdatedFooter(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Text(
        'Last updated $_lastUpdated · $_doctorName',
        style: TextStyle(fontSize: 11, color: colors.textSecondary),
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

  String _fmtHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    return hour < 12
        ? '${hour.toString().padLeft(2, '0')}:00 AM'
        : '${(hour - 12).toString().padLeft(2, '0')}:00 PM';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _GlucoseRangeBar extends StatelessWidget {
  final int min;
  final int max;

  const _GlucoseRangeBar({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: CustomPaint(
            size: const Size(double.infinity, 44),
            painter: _RangeBarPainter(targetMin: min, targetMax: max),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '40',
              style: TextStyle(fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '54',
              style: TextStyle(fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '70',
              style: TextStyle(fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '180',
              style: TextStyle(fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '250',
              style: TextStyle(fontSize: 9, color: colors.textSecondary),
            ),
            Text(
              '400',
              style: TextStyle(fontSize: 9, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Very Low',
              style: TextStyle(fontSize: 8, color: Color(0xFFB71C1C)),
            ),
            Text(
              'Low',
              style: TextStyle(fontSize: 8, color: Color(0xFFFBC02D)),
            ),
            Text(
              'In Range',
              style: TextStyle(fontSize: 8, color: Color(0xFF2BB6A3)),
            ),
            Text(
              'High',
              style: TextStyle(fontSize: 8, color: Color(0xFFFF9F40)),
            ),
            Text(
              'Very High',
              style: TextStyle(fontSize: 8, color: Color(0xFFD32F2F)),
            ),
          ],
        ),
      ],
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  final int targetMin;
  final int targetMax;

  static const double _scaleMin = 40;
  static const double _scaleMax = 400;

  const _RangeBarPainter({required this.targetMin, required this.targetMax});

  double _x(double glucose, double width) {
    return (glucose - _scaleMin) / (_scaleMax - _scaleMin) * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double barH = 18;
    final double barTop = (h - barH) / 2;
    final radius = Radius.circular(barH / 2);

    final x54 = _x(54, w);
    final x70 = _x(70, w);
    final x180 = _x(180, w);
    final x250 = _x(250, w);

    final segments = [
      (0.0, x54, const Color(0xFFB71C1C)),
      (x54, x70, const Color(0xFFFBC02D)),
      (x70, x180, const Color(0xFF2BB6A3)),
      (x180, x250, const Color(0xFFFF9F40)),
      (x250, w, const Color(0xFFD32F2F)),
    ];

    for (int i = 0; i < segments.length; i++) {
      final (x1, x2, color) = segments[i];
      final rect = Rect.fromLTWH(x1, barTop, x2 - x1, barH);
      final isFirst = i == 0;
      final isLast = i == segments.length - 1;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: isFirst ? radius : Radius.zero,
          bottomLeft: isFirst ? radius : Radius.zero,
          topRight: isLast ? radius : Radius.zero,
          bottomRight: isLast ? radius : Radius.zero,
        ),
        Paint()..color = color.withAlpha(180),
      );
    }

    final txMin = _x(targetMin.toDouble(), w);
    final txMax = _x(targetMax.toDouble(), w);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(txMin, barTop - 4, txMax - txMin, barH + 8),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.white.withAlpha(80)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(txMin, barTop - 4, txMax - txMin, barH + 8),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final midX = (txMin + txMax) / 2;
    final tp = TextPainter(
      text: TextSpan(
        text: 'Target',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(midX - tp.width / 2, barTop - 3));
  }

  @override
  bool shouldRepaint(_RangeBarPainter old) =>
      old.targetMin != targetMin || old.targetMax != targetMax;
}
