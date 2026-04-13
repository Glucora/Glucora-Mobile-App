import 'package:flutter/material.dart';
import '../../../core/models/guardian_patient_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/shared/widgets/location_widget.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class GuardianPatientDetailScreen extends StatefulWidget {
  final GuardianPatient patient;
  final int initialTab;

  const GuardianPatientDetailScreen({
    super.key,
    required this.patient,
    this.initialTab = 0,
  });

  @override
  State<GuardianPatientDetailScreen> createState() =>
      _GuardianPatientDetailScreenState();
}

class _GuardianPatientDetailScreenState
    extends State<GuardianPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static Color statusColor(String s, GlucoraColors colors) {
    switch (s) {
      case 'emergency':
        return colors.error;
      case 'attention':
        return colors.warning;
      default:
        return colors.accent;
    }
  }

  static Color glucoseColor(GuardianPatient p, GlucoraColors colors) {
    switch (p.glucoseLabel) {
      case 'Too high':
      case 'Very high':
      case 'Too low':
      case 'Very low':
        return colors.error;
      case 'A bit high':
        return colors.warning;
      default:
        return colors.accent;
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _call() async {
    final phone = widget.patient.phoneNumber;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('No phone number available')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sms() async {
    final phone = widget.patient.phoneNumber;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('No phone number available')),
      );
      return;
    }
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = widget.patient;
    final sColor = statusColor(p.overallStatus, colors);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (ctx, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return Column(
              children: [
                Container(
                  color: colors.surface,
                  padding: EdgeInsets.fromLTRB(
                    8,
                    isLandscape ? 8 : 14,
                    16,
                    isLandscape ? 8 : 14,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        color: colors.textPrimary,
                      ),
                      CircleAvatar(
                        radius: isLandscape ? 18 : 22,
                        backgroundColor: sColor.withValues(alpha: 0.12),
                        child: TranslatedText(
                          p.name.substring(0, 1),
                          style: TextStyle(
                            color: sColor,
                            fontWeight: FontWeight.w800,
                            fontSize: isLandscape ? 14 : 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              p.name,
                              style: TextStyle(
                                fontSize: isLandscape ? 15 : 18,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            TranslatedText(
                              '${p.relationship}  ·  Age ${p.age}  ·  Type 1',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: sColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TranslatedText(
                          p.overallStatus == 'emergency'
                              ? 'Needs help now'
                              : p.overallStatus == 'attention'
                              ? 'Needs attention'
                              : 'Doing well',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sms,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.sms_rounded,
                            color: colors.warning,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _call,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.call_rounded,
                            color: colors.accent,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tab,
                    labelColor: colors.accent,
                    unselectedLabelColor: colors.textSecondary,
                    indicatorColor: colors.accent,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Location'),
                      Tab(text: 'Doctor Plan'),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _OverviewTab(patient: p, isLandscape: isLandscape),
                      LocationView(
                        patient: LocationPatientInfo(
                          patientUserId: p.patientId,
                          fullName: p.name,
                        ),
                        isLandscape: isLandscape,
                        userRole: 'guardian',
                      ),
                      _DoctorPlanTab(patient: p, isLandscape: isLandscape),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── OVERVIEW TAB ────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _OverviewTab({required this.patient, required this.isLandscape});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  GuardianPatient get patient => widget.patient;
  bool get isLandscape => widget.isLandscape;

  // Total insulin delivered today — null means still loading
  double? _totalInsulinToday;

  // Today's glucose readings keyed by time-of-day slot
  // Each entry: { 'value': double, 'inRange': bool, 'label': String }
  Map<String, Map<String, dynamic>> _glucoseSlots = {};
  bool _glucoseSlotsLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchTotalInsulin();
    _fetchTodayGlucoseSlots();
  }

  // ── Insulin ────────────────────────────────────────────────────────────────

  Future<void> _fetchTotalInsulin() async {
    try {
      final today = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final endOfDay = DateTime.utc(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toIso8601String();

      final rows = await Supabase.instance.client
          .from('insulin_doses')
          .select('units')
          .eq('patient_id', widget.patient.profileId!)
          .gte('delivered_at', startOfDay)
          .lte('delivered_at', endOfDay);

      if (!mounted) return;
      double total = 0;
      for (final row in rows as List) {
        total += (row['units'] as num?)?.toDouble() ?? 0;
      }
      setState(() => _totalInsulinToday = total);
    } catch (_) {
      if (mounted) setState(() => _totalInsulinToday = null);
    }
  }

  String get _totalInsulinLabel {
    if (_totalInsulinToday == null) return '—';
    final formatted = _totalInsulinToday!.toStringAsFixed(1);
    return '${formatted.endsWith('.0') ? formatted.split('.')[0] : formatted} U';
  }

  // ── Today at a Glance ──────────────────────────────────────────────────────
  // Fetches glucose readings for today and buckets them into time slots:
  //   morning  = 05:00–09:59 local
  //   breakfast = 07:00–10:59 local  (first reading after morning)
  //   midday   = 11:00–14:59 local
  // "Now" is always derived from the live patient.glucoseValue from the model.

  Future<void> _fetchTodayGlucoseSlots() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      final endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toUtc();

      final rows = await Supabase.instance.client
          .from('glucose_readings')
          .select('value_mg_dl, recorded_at')
          .eq('patient_id', widget.patient.profileId!)
          .gte('recorded_at', startOfDay.toIso8601String())
          .lte('recorded_at', endOfDay.toIso8601String())
          .order('recorded_at', ascending: false); // Get most recent first

      if (!mounted) return;

      final slots = <String, Map<String, dynamic>>{};

      // If we have readings, just take the most recent ones
      // No time slot restrictions - just show what we have!
      final readingsList = rows as List;

      if (readingsList.isNotEmpty) {
        // Take up to 3 most recent readings
        for (int i = 0; i < readingsList.length && i < 3; i++) {
          final row = readingsList[i];
          final value = (row['value_mg_dl'] as num?)?.toDouble();
          if (value == null) continue;

          final recorded = DateTime.tryParse(
            row['recorded_at'] as String? ?? '',
          )?.toLocal();
          if (recorded == null) continue;

          final inRange = value >= 70 && value <= 180;

          // Use time as the key instead of fixed slots
          final timeKey = _formatTimeKey(recorded);
          slots[timeKey] = {
            'value': value,
            'inRange': inRange,
            'time': recorded,
          };
        }
      }

      setState(() {
        _glucoseSlots = slots;
        _glucoseSlotsLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _glucoseSlotsLoaded = true);
    }
  }

  String _formatTimeKey(DateTime time) {
    // Returns something like "2:30 PM"
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color gColor(BuildContext context) {
    final colors = context.colors;
    return _GuardianPatientDetailScreenState.glucoseColor(patient, colors);
  }

  IconData get tIcon {
    switch (patient.glucoseTrend) {
      case 'up':
        return Icons.trending_up_rounded;
      case 'down':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: isLandscape
              ? SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _glucoseCard(context),
                            const SizedBox(height: 14),
                            _devicesCard(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            _insulinCard(context),
                            const SizedBox(height: 14),
                            _todayCard(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : SliverList(
                  delegate: SliverChildListDelegate([
                    _glucoseCard(context),
                    const SizedBox(height: 14),
                    _devicesCard(context),
                    const SizedBox(height: 14),
                    _insulinCard(context),
                    const SizedBox(height: 14),
                    _todayCard(context),
                  ]),
                ),
        ),
      ],
    );
  }

  Widget _glucoseCard(BuildContext context) {
    final colors = context.colors;
    final glucoseColorVal = gColor(context);
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel(context, 'Blood Sugar Right Now'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TranslatedText(
                '${patient.glucoseValue}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: glucoseColorVal,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TranslatedText(
                  'mg/dL',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: glucoseColorVal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(tIcon, color: glucoseColorVal, size: 14),
                    const SizedBox(width: 5),
                    TranslatedText(
                      patient.glucoseLabel,
                      style: TextStyle(
                        color: glucoseColorVal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rangeBar(context),
        ],
      ),
    );
  }

  Widget _rangeBar(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TranslatedText(
              'Too Low',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
            TranslatedText(
              'Normal Range',
              style: TextStyle(
                fontSize: 10,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            TranslatedText(
              'Too High',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(color: colors.error.withValues(alpha: 0.3)),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    color: colors.warning.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (ctx, constraints) {
            const double minV = 40, maxV = 300;
            final double pct = ((patient.glucoseValue - minV) / (maxV - minV))
                .clamp(0.0, 1.0);
            final glucoseColorVal = gColor(context);
            return Stack(
              children: [
                const SizedBox(height: 14, width: double.infinity),
                Positioned(
                  left: (constraints.maxWidth * pct - 6).clamp(
                    0.0,
                    constraints.maxWidth - 12,
                  ),
                  child: Icon(
                    Icons.arrow_drop_up_rounded,
                    color: glucoseColorVal,
                    size: 20,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _devicesCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel(context, 'Devices'),
          const SizedBox(height: 12),
          _deviceRow(
            context,
            Icons.sensors,
            'Sugar Sensor',
            patient.sensorConnected ? 'Connected' : 'Disconnected',
            patient.sensorConnected,
          ),
          const SizedBox(height: 8),
          _deviceRow(
            context,
            Icons.water_drop_outlined,
            'Insulin Pump',
            patient.pumpActive ? 'Working' : 'Paused',
            patient.pumpActive,
          ),
        ],
      ),
    );
  }

  Widget _deviceRow(
    BuildContext context,
    IconData icon,
    String label,
    String status,
    bool ok,
  ) {
    final colors = context.colors;
    final color = ok ? colors.accent : colors.error;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        TranslatedText(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TranslatedText(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _insulinCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel(context, 'Insulin Today'),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(colors, '${patient.dosesToday}', 'Doses given'),
              _divider(context),
              _stat(
                colors,
                patient.allDosesAutomatic ? 'Auto' : 'Manual',
                'How given',
              ),
              _divider(context),
              _stat(colors, _totalInsulinLabel, 'Total amount'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: colors.accent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TranslatedText(
                    patient.allDosesAutomatic
                        ? 'The device handled everything automatically today.'
                        : 'Some doses were given manually today.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.accent,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  Widget _stat(GlucoraColors colors, String val, String label) => Expanded(
    child: Column(
      children: [
        TranslatedText(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        TranslatedText(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: colors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    ),
  );

  Widget _divider(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 36,
      width: 1,
      color: colors.textSecondary.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _todayCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel(context, 'Latest Readings'),
          const SizedBox(height: 12),
          _latestReadingsList(context),
        ],
      ),
    );
  }

  Widget _latestReadingsList(BuildContext context) {
    final colors = context.colors;

    if (!_glucoseSlotsLoaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Convert slots to list and sort by time (morning -> breakfast -> midday)
    final List<MapEntry<String, Map<String, dynamic>>> readings = _glucoseSlots
        .entries
        .toList();

    // Define order priority
    final order = {'morning': 0, 'breakfast': 1, 'midday': 2};
    readings.sort(
      (a, b) => (order[a.key] ?? 999).compareTo(order[b.key] ?? 999),
    );

    if (readings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: TranslatedText(
            'No readings recorded today',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final entry in readings.take(3)) ...[
          _readingRow(
            context,
            _getTimeLabel(entry.key),
            (entry.value['value'] as double).toInt(),
            entry.value['inRange'] as bool,
          ),
          if (entry != readings.last) const SizedBox(height: 10),
        ],
        // Always show current reading
        const Divider(height: 20),
        _readingRow(
          context,
          'Current',
          patient.glucoseValue,
          patient.glucoseLabel == 'In Range',
          isCurrent: true,
        ),
      ],
    );
  }

  Widget _readingRow(
    BuildContext context,
    String timeLabel,
    int value,
    bool inRange, {
    bool isCurrent = false,
  }) {
    final colors = context.colors;
    final valueColor = inRange
        ? colors.accent
        : (value < 70 ? colors.error : colors.warning);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: valueColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: TranslatedText(
            timeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: TranslatedText(
            _getReadingDescription(value, inRange),
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TranslatedText(
            '$value mg/dL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeLabel(String slot) {
    switch (slot) {
      case 'morning':
        return 'Morning';
      case 'breakfast':
        return 'Breakfast';
      case 'midday':
        return 'Midday';
      default:
        return slot;
    }
  }

  String _getReadingDescription(int value, bool inRange) {
    if (inRange) {
      return 'In safe range';
    } else if (value < 70) {
      return 'Low - needs attention';
    } else {
      return 'High - needs attention';
    }
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _secLabel(BuildContext context, String text) {
    final colors = context.colors;
    return TranslatedText(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── DOCTOR PLAN TAB ─────────────────────────────────────────────────────────

// Simple data class to hold the fetched care plan
class _CarePlanData {
  final double targetMin;
  final double targetMax;
  final String insulinType;
  final double maxAutoDose;
  final bool aidModeEnabled;
  final String? notes;
  final DateTime? nextAppointment;
  final String doctorName;
  final DateTime? updatedAt;

  const _CarePlanData({
    required this.targetMin,
    required this.targetMax,
    required this.insulinType,
    required this.maxAutoDose,
    required this.aidModeEnabled,
    this.notes,
    this.nextAppointment,
    required this.doctorName,
    this.updatedAt,
  });
}

class _DoctorPlanTab extends StatefulWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _DoctorPlanTab({required this.patient, required this.isLandscape});

  @override
  State<_DoctorPlanTab> createState() => _DoctorPlanTabState();
}

class _DoctorPlanTabState extends State<_DoctorPlanTab> {
  _CarePlanData? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCarePlan();
  }

  Future<void> _fetchCarePlan() async {
    try {
      print(
        "🔍 [DoctorPlan] Fetching for patientId: ${widget.patient.patientId}",
      );

      // Fetch with nested doctor data like the doctor side does
      final response = await Supabase.instance.client
          .from('care_plans')
          .select('''
          target_glucose_min, 
          target_glucose_max, 
          insulin_type, 
          max_auto_dose_units, 
          aid_mode_enabled, 
          notes, 
          next_appointment, 
          updated_at,
          doctor_profile!care_plans_doctor_id_fkey(
            user_id,
            users(
              full_name
            )
          )
        ''')
          .eq('patient_id', widget.patient.profileId!)
          .order('updated_at', ascending: false)
          .limit(1);

      print(" [DoctorPlan] Response type: ${response.runtimeType}");
      print(" [DoctorPlan] Response: $response");

      final plans = response as List;
      if (plans.isEmpty) {
        print(" [DoctorPlan] No care plan found");
        if (mounted) {
          setState(() {
            _error = 'No care plan available for this patient';
            _loading = false;
          });
        }
        return;
      }

      final planRow = plans.first;
      print(" [DoctorPlan] Plan found: ${planRow['id']}");

      // Extract doctor name from nested structure
      String doctorName = 'Your Doctor';
      final doctorProfile = planRow['doctor_profile'];
      print(" [DoctorPlan] doctorProfile: $doctorProfile");

      if (doctorProfile != null) {
        final users = doctorProfile['users'];
        print(" [DoctorPlan] users: $users");
        if (users != null && users['full_name'] != null) {
          final rawName = users['full_name'] as String;
          doctorName = rawName.startsWith('Dr') ? rawName : 'Dr. $rawName';
          print(" [DoctorPlan] Doctor name: $doctorName");
        }
      }

      if (!mounted) return;
      setState(() {
        _plan = _CarePlanData(
          targetMin: (planRow['target_glucose_min'] as num?)?.toDouble() ?? 70,
          targetMax: (planRow['target_glucose_max'] as num?)?.toDouble() ?? 180,
          insulinType: planRow['insulin_type'] as String? ?? 'Not specified',
          maxAutoDose:
              (planRow['max_auto_dose_units'] as num?)?.toDouble() ?? 0,
          aidModeEnabled: planRow['aid_mode_enabled'] as bool? ?? false,
          notes: planRow['notes'] as String?,
          nextAppointment: planRow['next_appointment'] != null
              ? DateTime.tryParse(planRow['next_appointment'] as String)
              : null,
          doctorName: doctorName,
          updatedAt: planRow['updated_at'] != null
              ? DateTime.tryParse(planRow['updated_at'] as String)
              : null,
        );
        _loading = false;
      });
    } catch (e, stackTrace) {
      print(" [DoctorPlan] ERROR: $e");
      print(" [DoctorPlan] StackTrace: $stackTrace");
      if (!mounted) return;
      setState(() {
        _error = 'Could not load doctor plan: $e';
        _loading = false;
      });
    }
  }

  /// Returns how many days from today to [date], formatted as a human string.
  String _daysFromNow(DateTime date) {
    final today = DateTime.now();
    final diff = date
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${diff.abs()} days ago';
    return '$diff days from now';
  }

  /// Formats [date] as e.g. "April 2, 2025"
  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats [updatedAt] as e.g. "March 15" for the doctor card subtitle.
  String _formatShortDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }

    if (_error != null || _plan == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 48,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            TranslatedText(
              _error ?? 'No plan available',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final plan = _plan!;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            widget.isLandscape ? 12 : 24,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Doctor header card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accent, colors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            plan.doctorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TranslatedText(
                            plan.updatedAt != null
                                ? 'Endocrinologist  ·  Last updated ${_formatShortDate(plan.updatedAt!)}'
                                : 'Endocrinologist',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const TranslatedText(
                        'Read Only',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Safe Sugar Range ──
              _planCard(
                context,
                title: 'Safe Sugar Range',
                child: Row(
                  children: [
                    Expanded(
                      child: _rangeBox(
                        context,
                        'Lowest safe',
                        '${plan.targetMin.toStringAsFixed(0)} mg/dL',
                        'Below this is too low',
                        colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _rangeBox(
                        context,
                        'Highest safe',
                        '${plan.targetMax.toStringAsFixed(0)} mg/dL',
                        'Above this is too high',
                        colors.warning,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Insulin Being Used ──
              _planCard(
                context,
                title: 'Insulin Being Used',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      plan.insulinType,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TranslatedText(
                      'This insulin works quickly. The device gives it automatically when needed.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── How the Device Works ──
              _planCard(
                context,
                title: 'How the Device Works',
                child: Column(
                  children: [
                    _planRow(
                      context,
                      'Mode',
                      plan.aidModeEnabled
                          ? 'Fully automatic — no manual doses needed'
                          : 'Manual mode — doses given by hand',
                    ),
                    _planRow(
                      context,
                      'Max dose',
                      'Up to ${plan.maxAutoDose.toStringAsFixed(0)} units at a time',
                    ),
                    _planRow(
                      context,
                      'Low sugar',
                      'Pauses insulin if sugar drops below ${plan.targetMin.toStringAsFixed(0)}',
                    ),
                    _planRow(
                      context,
                      'High sugar',
                      'Gives extra insulin if sugar goes above ${plan.targetMax.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              // ── Next Doctor Visit (only if available) ──
              if (plan.nextAppointment != null) ...[
                const SizedBox(height: 14),
                _planCard(
                  context,
                  title: 'Next Doctor Visit',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: colors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            _formatDate(plan.nextAppointment!),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TranslatedText(
                            _daysFromNow(plan.nextAppointment!),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ── Doctor's Notes (only if available) ──
              if (plan.notes != null && plan.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _planCard(
                  context,
                  title: "Doctor's Notes for You",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: plan.notes!
                        .split('\n')
                        .where((line) => line.trim().isNotEmpty)
                        .map((line) => _note(context, line.trim()))
                        .toList(),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _planCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _rangeBox(
    BuildContext context,
    String label,
    String value,
    String sub,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TranslatedText(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          TranslatedText(
            sub,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _planRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: TranslatedText(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: TranslatedText(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F5F3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final grid = Paint()
      ..color = const Color(0xFFCCE8E3).withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 9;
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.45),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.55, size.height),
      road,
    );

    final block = Paint()
      ..color = const Color(0xFFB2D8D2).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.08,
          size.width * 0.3,
          size.height * 0.3,
        ),
        const Radius.circular(4),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.1,
          size.width * 0.28,
          size.height * 0.25,
        ),
        const Radius.circular(4),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.64,
          size.width * 0.25,
          size.height * 0.26,
        ),
        const Radius.circular(4),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.64,
          size.width * 0.3,
          size.height * 0.28,
        ),
        const Radius.circular(4),
      ),
      block,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
