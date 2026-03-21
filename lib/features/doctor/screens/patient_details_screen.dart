import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'care_plan_editor_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientName;

  const PatientDetailsScreen({
    super.key,
    required this.patientName,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<GlucoseReading> glucoseHistory = [
    GlucoseReading(time: '12am', value: 142),
    GlucoseReading(time: '12:30', value: 138),
    GlucoseReading(time: '1am', value: 130),
    GlucoseReading(time: '1:30', value: 124),
    GlucoseReading(time: '2am', value: 118),
    GlucoseReading(time: '2:30', value: 115),
    GlucoseReading(time: '3am', value: 112),
    GlucoseReading(time: '3:30', value: 108),
    GlucoseReading(time: '4am', value: 104),
    GlucoseReading(time: '4:30', value: 98),
    GlucoseReading(time: '5am', value: 95),
    GlucoseReading(time: '5:30', value: 92),
    GlucoseReading(time: '6am', value: 88),
    GlucoseReading(time: '6:30', value: 102),
    GlucoseReading(time: '7am', value: 118),
    GlucoseReading(time: '7:30', value: 145),
    GlucoseReading(time: '8am', value: 172, mealTag: 'Breakfast'),
    GlucoseReading(time: '8:30', value: 198),
    GlucoseReading(time: '9am', value: 185),
    GlucoseReading(time: '9:30', value: 162),
    GlucoseReading(time: '10am', value: 145),
    GlucoseReading(time: '10:30', value: 132),
    GlucoseReading(time: '11am', value: 120),
    GlucoseReading(time: '11:30', value: 115),
    GlucoseReading(time: '12pm', value: 112, mealTag: 'Lunch'),
    GlucoseReading(time: '12:30', value: 168),
    GlucoseReading(time: '1pm', value: 188),
    GlucoseReading(time: '1:30', value: 175),
    GlucoseReading(time: '2pm', value: 158),
    GlucoseReading(time: '2:30', value: 140),
    GlucoseReading(time: '3pm', value: 128),
    GlucoseReading(time: '3:30', value: 120),
    GlucoseReading(time: '4pm', value: 118),
    GlucoseReading(time: '4:30', value: 115),
    GlucoseReading(time: '5pm', value: 110),
    GlucoseReading(time: '5:30', value: 108),
    GlucoseReading(time: '6pm', value: 130, mealTag: 'Dinner'),
    GlucoseReading(time: '6:30', value: 162),
    GlucoseReading(time: '7pm', value: 178),
    GlucoseReading(time: '7:30', value: 165),
    GlucoseReading(time: '8pm', value: 148),
    GlucoseReading(time: '8:30', value: 135),
    GlucoseReading(time: '9pm', value: 128),
    GlucoseReading(time: '9:30', value: 122),
    GlucoseReading(time: '10pm', value: 118),
    GlucoseReading(time: '10:30', value: 115),
    GlucoseReading(time: '11pm', value: 112),
    GlucoseReading(time: '11:30', value: 120),
  ];

  final List<InsulinDose> insulinLog = [
    InsulinDose(time: '8:02 AM', type: 'Bolus', units: 4.5, reason: 'Meal — Breakfast', source: 'AID Auto'),
    InsulinDose(time: '8:35 AM', type: 'Correction', units: 1.2, reason: 'High correction', source: 'AID Auto'),
    InsulinDose(time: '12:05 PM', type: 'Bolus', units: 5.0, reason: 'Meal — Lunch', source: 'Manual'),
    InsulinDose(time: '1:40 PM', type: 'Correction', units: 0.8, reason: 'High correction', source: 'AID Auto'),
    InsulinDose(time: '6:10 PM', type: 'Bolus', units: 4.2, reason: 'Meal — Dinner', source: 'AID Auto'),
    InsulinDose(time: '9:00 PM', type: 'Basal', units: 12.0, reason: 'Nightly basal', source: 'Pump Program'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildPatientHeader(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: [
                _buildOverviewTab(context),
                _buildCGMTab(context),
                _buildInsulinTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.patientName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
          const Text(
            'Patient ID: #PT-20481',
            style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Alerts',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Text('AK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Age 24 • Male • Type 1 Diabetes',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _headerChip(Icons.bluetooth, 'CGM Online', Colors.greenAccent),
                    const SizedBox(width: 8),
                    _headerChip(Icons.water_drop_outlined, 'Pump Active', Colors.lightBlueAccent),
                  ],
                )
              ],
            ),
          ),
          _buildLiveGlucoseChip(),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLiveGlucoseChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('120', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
                  const Text('mg/dL', style: TextStyle(color: Colors.white70, fontSize: 9)),
                ],
              ),
            ],
          ),
          const Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colors.primaryDark,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.accent,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'CGM Trends'),
          Tab(text: 'Insulin Log'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Glucose Summary — Last 24h'),
          const SizedBox(height: 12),
          _buildGlucoseSummaryCards(context),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Time In Range'),
          const SizedBox(height: 12),
          _buildTimeInRangeCard(context),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Pump Status'),
          const SizedBox(height: 12),
          _buildPumpStatusCard(context),
          const SizedBox(height: 36),
          _sectionTitle(context, 'AID System Status'),
          const SizedBox(height: 12),
          _buildAIDStatusCard(context),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Active Alerts'),
          const SizedBox(height: 12),
          _buildAlertsCard(context),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Care Plan'),
          const SizedBox(height: 12),
          _buildCarePlanCard(context),
          const SizedBox(height: 36),
          _buildDeletePatientButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDeletePatientButton(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showDeleteConfirmation(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.error,
          side: BorderSide(color: colors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.person_remove_outlined, size: 18),
        label: const Text(
          'Remove Patient',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.error, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Remove Patient',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to remove '),
              TextSpan(
                text: widget.patientName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text: ' from your patient list?\n\nThis will disconnect them from your care and cannot be undone.',
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colors.textSecondary.withValues(alpha:0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildGlucoseSummaryCards(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: _statCard(context, 'Average\nGlucose', '132', 'mg/dL', colors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, 'GMI\nEst. A1C', '6.8', '%', const Color(0xFF5B8CF5))),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, 'Glucose\nVariability', '18', 'CV%', colors.warning)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, 'Sensor\nUsage', '96', '%', const Color(0xFF6FCF97))),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, String unit, Color color) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(unit, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: colors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTimeInRangeCard(BuildContext context) {
    const double inRange = 72;
    const double aboveRange = 18;
    const double belowRange = 6;
    const double veryLow = 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tirRow('Very High (>250)', 4, const Color(0xFFD32F2F)),
                    const SizedBox(height: 6),
                    _tirRow('High (181–250)', aboveRange.toInt(), const Color(0xFFFF9F40)),
                    const SizedBox(height: 6),
                    _tirRow('In Range (70–180)', inRange.toInt(), const Color(0xFF2BB6A3)),
                    const SizedBox(height: 6),
                    _tirRow('Low (54–69)', belowRange.toInt(), const Color(0xFFFBC02D)),
                    const SizedBox(height: 6),
                    _tirRow('Very Low (<54)', veryLow.toInt(), const Color(0xFFB71C1C)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: TIRPieChartPainter(
                    segments: [
                      TIRSegment(percent: 4, color: const Color(0xFFD32F2F)),
                      TIRSegment(percent: aboveRange, color: const Color(0xFFFF9F40)),
                      TIRSegment(percent: inRange, color: const Color(0xFF2BB6A3)),
                      TIRSegment(percent: belowRange, color: const Color(0xFFFBC02D)),
                      TIRSegment(percent: veryLow, color: const Color(0xFFB71C1C)),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('72%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2BB6A3))),
                        Text('TIR', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                _tirBar(4, const Color(0xFFD32F2F)),
                _tirBar(aboveRange, const Color(0xFFFF9F40)),
                _tirBar(inRange, const Color(0xFF2BB6A3)),
                _tirBar(belowRange, const Color(0xFFFBC02D)),
                _tirBar(veryLow, const Color(0xFFB71C1C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tirRow(String label, int percent, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87))),
        Text('$percent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _tirBar(double percent, Color color) {
    return Flexible(
      flex: percent.toInt(),
      child: Container(height: 10, color: color),
    );
  }

  Widget _buildPumpStatusCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop, color: colors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Omnipod 5 — Pump', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary)),
                    Text('Last sync: 2 min ago', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge(context, 'Active', Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _pumpStat('Reservoir', '142 U', 'Remaining', const Color(0xFF5B8CF5))),
              const SizedBox(width: 10),
              Expanded(child: _pumpStat('Battery', '78%', 'Pump battery', const Color(0xFF6FCF97))),
              const SizedBox(width: 10),
              Expanded(child: _pumpStat('Basal Rate', '0.85 U/h', 'Current', colors.warning)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _pumpStat('Total Daily\nDose', '38.7 U', 'Today so far', colors.accent)),
              const SizedBox(width: 10),
              Expanded(child: _pumpStat('Basal Today', '20.4 U', 'Delivered', Colors.blueGrey)),
              const SizedBox(width: 10),
              Expanded(child: _pumpStat('Bolus Today', '18.3 U', 'Delivered', const Color(0xFFFF6B6B))),
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
                Icon(Icons.info_outline, color: colors.warning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Temp basal: +20% active for 45 min (AID adjustment)',
                    style: TextStyle(fontSize: 12, color: colors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pumpStat(String label, String value, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.4)),
        const SizedBox(height: 1),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIDStatusCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8CF5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF5B8CF5), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI-Powered AID System', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Model: ClosedLoop v3.2 • Adaptive mode', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge(context, 'AUTO', const Color(0xFF5B8CF5)),
            ],
          ),
          const SizedBox(height: 18),
          _aidRow(Icons.show_chart, 'Predicted Glucose (30 min)', '126 mg/dL', colors.textPrimary),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(Icons.trending_up, 'Current Glucose Trend', '↗ Rising slowly (+2 mg/dL·min)', colors.accent),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(Icons.bolt, 'Next Auto-Bolus', '0.3 U in ~8 min (predicted high)', colors.warning),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(Icons.do_not_disturb_alt, 'Suspend Guard', 'Active below 70 mg/dL', colors.error),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(Icons.tune, 'Insulin Sensitivity Factor', '1 U : 45 mg/dL (current)', Colors.blueGrey),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(Icons.rice_bowl_outlined, 'Insulin-to-Carb Ratio', '1 U : 12g carbs', Colors.blueGrey),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AID system is performing well. Glucose has remained in target range for 72% of today.',
                    style: TextStyle(fontSize: 12, color: colors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aidRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _alertRow(Icons.warning_amber_rounded, 'HIGH ALERT', 'Glucose reached 198 mg/dL at 8:30 AM — Auto correction delivered', colors.warning, '8:30 AM'),
          const Divider(height: 20),
          _alertRow(Icons.arrow_downward_rounded, 'LOW PREDICTED', 'Predictive low alert at 6:00 AM — Basal suspended for 30 min', const Color(0xFFFBC02D), '6:00 AM'),
          const Divider(height: 20),
          _alertRow(Icons.check_circle_outline, 'RESOLVED', 'Glucose stabilized after correction at 9:30 AM', colors.success, '9:30 AM'),
        ],
      ),
    );
  }

  Widget _alertRow(IconData icon, String tag, String message, Color color, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                  ),
                  const Spacer(),
                  Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 6),
              Text(message, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarePlanCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _carePlanRow('Target Range', '70 – 180 mg/dL', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Insulin Type', 'NovoLog (Fast-Acting)', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Daily Basal Program', '0.85 U/h (00:00–06:00), 1.0 U/h (06:00–12:00), 0.9 U/h (12:00–24:00)', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Max Auto-Bolus', '4.0 U per event', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Physician', 'Dr. Sarah El-Amin, Endocrinology', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Next Appointment', 'March 15, 2025', context),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarePlanEditorScreen(
                      patientName: widget.patientName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
              label: const Text('Edit Care Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carePlanRow(String label, String value, BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: colors.textPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildCGMTab(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, '24-Hour Glucose Trace'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _legendDot(colors.accent, 'In Range'),
                    const SizedBox(width: 12),
                    _legendDot(colors.warning, 'Above Range'),
                    const SizedBox(width: 12),
                    _legendDot(colors.error, 'Below Range'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: CustomPaint(
                    size: const Size(double.infinity, 220),
                    painter: GlucoseChartPainter(readings: glucoseHistory),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['12am', '6am', '12pm', '6pm', '12am']
                      .map((t) => Text(t, style: TextStyle(fontSize: 10, color: colors.textSecondary)))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          _sectionTitle(context, 'CGM Device Info'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                _cgmRow('Device', 'Dexcom G7', context),
                _cgmRow('Sensor Serial', 'SN-47291-G7', context),
                _cgmRow('Sensor Age', '6 days, 4 hours', context),
                _cgmRow('Sensor Expiry', '1 day, 20 hours remaining', context),
                _cgmRow('Signal Strength', '●●●●○  Good', context),
                _cgmRow('Calibration', 'Factory calibrated (no fingerstick)', context),
                _cgmRow('MARD', '8.2% (mean absolute relative diff.)', context),
              ],
            ),
          ),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Recent Readings (Last 12)'),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(context),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 12,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final reading = glucoseHistory.reversed.toList()[index];
                return _readingListTile(reading, context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _readingListTile(GlucoseReading reading, BuildContext context) {
    final colors = context.colors;
    Color valueColor;
    String status;
    if (reading.value > 180) {
      valueColor = colors.warning;
      status = 'High';
    } else if (reading.value < 70) {
      valueColor = colors.error;
      status = 'Low';
    } else {
      valueColor = colors.accent;
      status = 'In Range';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: valueColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('${reading.value}', style: TextStyle(fontWeight: FontWeight.w800, color: valueColor, fontSize: 13)),
        ),
      ),
      title: Text('${reading.time}  •  $status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
      subtitle: reading.mealTag != null
          ? Row(children: [
              const Icon(Icons.restaurant, size: 11, color: Colors.grey),
              const SizedBox(width: 4),
              Text(reading.mealTag!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])
          : const Text('CGM reading', style: TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Text('mg/dL', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
    );
  }

  Widget _cgmRow(String label, String value, BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary))),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInsulinTab(BuildContext context) {
    final colors = context.colors;
    final totalBolus = insulinLog.where((d) => d.type != 'Basal').fold(0.0, (s, d) => s + d.units);
    final totalBasal = insulinLog.where((d) => d.type == 'Basal').fold(0.0, (s, d) => s + d.units);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, "Today's Insulin Summary"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statCard(context, 'Total\nBolus', totalBolus.toStringAsFixed(1), 'units', colors.accent)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(context, 'Total\nBasal', totalBasal.toStringAsFixed(1), 'units', const Color(0xFF5B8CF5))),
              const SizedBox(width: 10),
              Expanded(child: _statCard(context, 'Total\nDelivered', (totalBolus + totalBasal).toStringAsFixed(1), 'units', colors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _statCard(context, 'Auto\nDoses', '4', 'by AID', const Color(0xFF6FCF97))),
            ],
          ),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Dose Log'),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(context),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: insulinLog.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) => _insulinLogTile(insulinLog[i], context),
            ),
          ),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Active Insulin on Board (IOB)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('1.4 U', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF5B8CF5))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Insulin on Board', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
                          Text('Estimated from last 3h doses', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B8CF5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('DIA: 4h', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B8CF5))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('IOB decays to 0 around 2:30 PM. AID will account for active insulin before issuing next auto-bolus.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _insulinLogTile(InsulinDose dose, BuildContext context) {
    final colors = context.colors;
    Color typeColor;
    IconData typeIcon;
    switch (dose.type) {
      case 'Bolus':
        typeColor = colors.accent;
        typeIcon = Icons.arrow_upward_rounded;
        break;
      case 'Correction':
        typeColor = colors.warning;
        typeIcon = Icons.bolt;
        break;
      case 'Basal':
        typeColor = const Color(0xFF5B8CF5);
        typeIcon = Icons.water_drop_outlined;
        break;
      default:
        typeColor = colors.textSecondary;
        typeIcon = Icons.circle;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(typeIcon, color: typeColor, size: 18),
      ),
      title: Row(
        children: [
          Text('${dose.units} U  •  ${dose.type}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: dose.source == 'AID Auto' ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              dose.source,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: dose.source == 'AID Auto' ? Colors.green : colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text('${dose.time}  •  ${dose.reason}', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary, letterSpacing: -0.3, height: 1.0));
  }

  Widget _statusBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = context.colors;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 3))],
    );
  }
}

class GlucoseReading {
  final String time;
  final int value;
  final String? mealTag;
  GlucoseReading({required this.time, required this.value, this.mealTag});
}

class InsulinDose {
  final String time;
  final String type;
  final double units;
  final String reason;
  final String source;
  InsulinDose({required this.time, required this.type, required this.units, required this.reason, required this.source});
}

class GlucoseChartPainter extends CustomPainter {
  final List<GlucoseReading> readings;
  GlucoseChartPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    const double minGlucose = 40;
    const double maxGlucose = 300;
    const double targetLow = 70;
    const double targetHigh = 180;

    double xStep = size.width / (readings.length - 1);

    double toY(double val) {
      return size.height - ((val - minGlucose) / (maxGlucose - minGlucose)) * size.height;
    }

    final rangePaint = Paint()..color = const Color(0xFF2BB6A3).withValues(alpha: 0.07);
    canvas.drawRect(
      Rect.fromLTRB(0, toY(targetHigh), size.width, toY(targetLow)),
      rangePaint,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF2BB6A3).withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(0, toY(targetHigh)), Offset(size.width, toY(targetHigh)), linePaint);
    _drawDashedLine(canvas, Offset(0, toY(targetLow)), Offset(size.width, toY(targetLow)), linePaint);

    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < readings.length; i++) {
      final x = i * xStep;
      final y = toY(readings[i].value.toDouble());
      if (i == 0) { fillPath.lineTo(x, y); }
      else { fillPath.lineTo(x, y); }
    }
    fillPath.lineTo((readings.length - 1) * xStep, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF2BB6A3).withValues(alpha: 0.2), const Color(0xFF2BB6A3).withValues(alpha: 0.0)],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final curvePaint = Paint()
      ..color = const Color(0xFF2BB6A3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < readings.length; i++) {
      final x = i * xStep;
      final y = toY(readings[i].value.toDouble());
      if (i == 0) { path.moveTo(x, y); }
      else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, curvePaint);

    for (int i = 0; i < readings.length; i++) {
      if (readings[i].mealTag != null) {
        final x = i * xStep;
        final y = toY(readings[i].value.toDouble());
        final markerPaint = Paint()..color = const Color(0xFFFF9F40);
        canvas.drawCircle(Offset(x, y), 5, markerPaint);
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    final labelStyle = TextStyle(color: Colors.grey.shade400, fontSize: 9);
    for (final val in [70.0, 120.0, 180.0, 240.0]) {
      final tp = TextPainter(
        text: TextSpan(text: '${val.toInt()}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, toY(val) - 6));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double distance = 0;
    final len = end.dx - start.dx;
    while (distance < len) {
      canvas.drawLine(
        Offset(start.dx + distance, start.dy),
        Offset(start.dx + math.min(distance + dashWidth, len), start.dy),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TIRSegment {
  final double percent;
  final Color color;
  TIRSegment({required this.percent, required this.color});
}

class TIRPieChartPainter extends CustomPainter {
  final List<TIRSegment> segments;
  TIRPieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -math.pi / 2;

    for (final seg in segments) {
      final sweepAngle = 2 * math.pi * (seg.percent / 100);
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sweepAngle - 0.04,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}