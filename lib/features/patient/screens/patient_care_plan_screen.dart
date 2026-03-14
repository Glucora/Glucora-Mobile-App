import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/features/doctor/screens/care_plan.dart';

// ─── MOCK DATA ────────────────────────────────────────────────────────────────

final _mockPlan = CarePlan(
  targetGlucoseMin: 70,
  targetGlucoseMax: 180,
  insulinType: 'NovoLog (Fast-Acting)',
  basalProgram: [
    BasalSegment(startHour: 0, endHour: 6, rate: 0.85),
    BasalSegment(startHour: 6, endHour: 12, rate: 1.00),
    BasalSegment(startHour: 12, endHour: 24, rate: 0.90),
  ],
  insulinToCarbRatio: 12,
  sensitivityFactor: 45,
  maxAutoBolus: 4.0,
  nextAppointment: DateTime(2026, 4, 5),
  doctorNotes:
      'Maintain current basal program. Avoid skipping meals — always bolus before eating. '
      'If glucose drops below 70 mg/dL, take 15g fast-acting carbs and recheck in 15 minutes. '
      'Contact the clinic if you experience two or more unexplained highs above 250 mg/dL in a week.',
);

const _doctorName = 'Dr. Sarah Johnson';
const _lastUpdated = 'Mar 5, 2026';

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class PatientCarePlanScreen extends StatelessWidget {
  const PatientCarePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF199A8E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Care Plan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Set by $_doctorName',
              style: TextStyle(
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
            _infoChip(),
            const SizedBox(height: 28),

            _sectionHeader(
              Icons.track_changes_outlined,
              'Target Glucose Range',
            ),
            const SizedBox(height: 12),
            _targetRangeCard(_mockPlan),
            const SizedBox(height: 28),

            _sectionHeader(
              Icons.water_drop_outlined,
              'Insulin & Basal Program',
            ),
            const SizedBox(height: 12),
            _insulinBasalCard(_mockPlan),
            const SizedBox(height: 28),

            _sectionHeader(Icons.calculate_outlined, 'Dosing Ratios'),
            const SizedBox(height: 12),
            _dosingRatiosCard(_mockPlan),
            const SizedBox(height: 28),

            _sectionHeader(Icons.bolt_outlined, 'AID Settings'),
            const SizedBox(height: 12),
            _aidSettingsCard(_mockPlan),
            const SizedBox(height: 28),

            _sectionHeader(Icons.calendar_today_outlined, 'Next Appointment'),
            const SizedBox(height: 12),
            _appointmentCard(_mockPlan),
            const SizedBox(height: 28),

            _sectionHeader(Icons.notes_outlined, 'Doctor Notes'),
            const SizedBox(height: 12),
            _notesCard(_mockPlan),

            const SizedBox(height: 16),
            _lastUpdatedFooter(),
          ],
        ),
      ),
    );
  }

  // ─── INFO CHIP ────────────────────────────────────────────────

  Widget _infoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF199A8E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF199A8E).withValues(alpha: 0.3),
        ),
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

  // ─── SECTION HEADER ───────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF199A8E)),
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

  // ─── TARGET RANGE CARD ────────────────────────────────────────

  Widget _targetRangeCard(CarePlan plan) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient spectrum bar with target window overlay
          _GlucoseRangeBar(
            min: plan.targetGlucoseMin,
            max: plan.targetGlucoseMax,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _rangeChip(
                label: 'Minimum',
                value: '${plan.targetGlucoseMin} mg/dL',
                color: const Color(0xFF2BB6A3),
              ),
              const SizedBox(width: 12),
              _rangeChip(
                label: 'Maximum',
                value: '${plan.targetGlucoseMax} mg/dL',
                color: const Color(0xFFFF9F40),
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

  Widget _rangeChip({
    required String label,
    required String value,
    required Color color,
  }) {
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

  // ─── INSULIN & BASAL CARD ─────────────────────────────────────

  Widget _insulinBasalCard(CarePlan plan) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insulin type pill
          Row(
            children: [
              const Text(
                'Insulin Type',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
          const Text(
            'Basal Program',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...plan.basalProgram.asMap().entries.map(
            (e) => _basalSegmentRow(e.key, e.value, plan.basalProgram.length),
          ),
        ],
      ),
    );
  }

  Widget _basalSegmentRow(int index, BasalSegment seg, int total) {
    final isLast = index == total - 1;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF199A8E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF199A8E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_fmtHour(seg.startHour)} – ${_fmtHour(seg.endHour)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF199A8E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${seg.rate.toStringAsFixed(2)} U/h',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF199A8E),
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

  // ─── DOSING RATIOS CARD ───────────────────────────────────────

  Widget _dosingRatiosCard(CarePlan plan) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
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
              icon: Icons.trending_down_outlined,
              iconColor: const Color(0xFFFF9F40),
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

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
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
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C),
              height: 1,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── AID SETTINGS CARD ────────────────────────────────────────

  Widget _aidSettingsCard(CarePlan plan) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maximum Auto-Bolus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2B3C),
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'U / event',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bolt_outlined,
                  color: Color(0xFFFF9F40),
                  size: 28,
                ),
              ),
            ],
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

  // ─── APPOINTMENT CARD ─────────────────────────────────────────

  Widget _appointmentCard(CarePlan plan) {
    final date = plan.nextAppointment;
    final formatted = date != null ? _fmtDate(date) : 'Not scheduled';
    final daysUntil = date?.difference(DateTime.now()).inDays;

    return _card(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF199A8E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF199A8E),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2B3C),
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
                      color: daysUntil >= 0
                          ? const Color(0xFF199A8E)
                          : Colors.redAccent,
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

  // ─── NOTES CARD ───────────────────────────────────────────────

  Widget _notesCard(CarePlan plan) {
    if (plan.doctorNotes.trim().isEmpty) {
      return _card(
        child: Text(
          'No notes from your doctor.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return _card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          plan.doctorNotes,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A2B3C),
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // ─── LAST UPDATED FOOTER ──────────────────────────────────────

  Widget _lastUpdatedFooter() {
    return Center(
      child: Text(
        'Last updated $_lastUpdated · $_doctorName',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  // ─── CARD WRAPPER ─────────────────────────────────────────────

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

  // ─── HELPERS ──────────────────────────────────────────────────

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

// ─── GLUCOSE RANGE BAR (CustomPainter) ───────────────────────────────────────

class _GlucoseRangeBar extends StatelessWidget {
  final int min;
  final int max;

  const _GlucoseRangeBar({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
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
        // x-axis labels
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('40', style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text('54', style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text('70', style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text('180', style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text('250', style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text('400', style: TextStyle(fontSize: 9, color: Colors.grey)),
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

  // Glucose spectrum: 40 → 54 → 70 → 180 → 250 → 400
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

    // Segment stops
    final x54 = _x(54, w);
    final x70 = _x(70, w);
    final x180 = _x(180, w);
    final x250 = _x(250, w);

    // 1. Draw colour segments
    final segments = [
      (0.0, x54, const Color(0xFFB71C1C)), // Very Low  (< 54)
      (x54, x70, const Color(0xFFFBC02D)), // Low       (54–70)
      (x70, x180, const Color(0xFF2BB6A3)), // In Range  (70–180)
      (x180, x250, const Color(0xFFFF9F40)), // High      (180–250)
      (x250, w, const Color(0xFFD32F2F)), // Very High (> 250)
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

    // 2. Draw target window overlay (white semi-transparent bracket)
    final txMin = _x(targetMin.toDouble(), w);
    final txMax = _x(targetMax.toDouble(), w);

    // White overlay on target region
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(txMin, barTop - 4, txMax - txMin, barH + 8),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.white.withAlpha(80)
        ..style = PaintingStyle.fill,
    );

    // Bracket border
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

    // 3. Target label above centre
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
