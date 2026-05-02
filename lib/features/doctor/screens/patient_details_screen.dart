import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'care_plan_editor_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/shared/widgets/location_widget.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';

final supabase = Supabase.instance.client;

class PatientDetailsScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientDetailsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _patientProfile;
  Map<String, dynamic>? _carePlan;
  List<Map<String, dynamic>> _glucoseReadings = [];
  List<Map<String, dynamic>> _insulinDoses = [];
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic>? _device;
  Map<String, dynamic>? _latestPrediction;
  Map<String, dynamic>? _latestIob;
  bool _isLoading = true;
  String? _profilePictureUrl;
  
  // ✅ Add this to force rebuild of care plan card
  int _carePlanReloadKey = 0;

  List<GlucoseReading> get glucoseHistory => _glucoseReadings.map((r) {
    final dt = DateTime.parse(r['recorded_at']).toLocal();
    final hour = dt.hour;
    final min = dt.minute;
    final period = hour < 12 ? 'am' : 'pm';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final time = min == 0
        ? '$displayHour$period'
        : '$displayHour:${min.toString().padLeft(2, '0')}';
    return GlucoseReading(time: time, value: (r['value_mg_dl'] as num).toInt());
  }).toList();

  List<InsulinDose> get insulinLog => _insulinDoses.map((d) {
    final dt = DateTime.parse(d['delivered_at']).toLocal();
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final time = '$displayHour:$min $period';
    return InsulinDose(
      time: time,
      type: d['dose_type'] as String,
      units: (d['units'] as num).toDouble(),
      reason: d['reason'] as String? ?? '',
      source: d['delivery_method'] == 'Pump' ? 'AID Auto' : 'Manual',
    );
  }).toList();

  // ── Derived pump stats from insulin_doses ──────────────────────────────────
  double get _tddToday {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _insulinDoses
        .where((d) {
          final dt = DateTime.parse(d['delivered_at']).toLocal();
          return dt.isAfter(startOfDay);
        })
        .fold(0.0, (s, d) => s + (d['units'] as num).toDouble());
  }

  double get _basalToday {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _insulinDoses
        .where((d) {
          final dt = DateTime.parse(d['delivered_at']).toLocal();
          return dt.isAfter(startOfDay) && d['dose_type'] == 'Basal';
        })
        .fold(0.0, (s, d) => s + (d['units'] as num).toDouble());
  }

  double get _bolusToday {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _insulinDoses
        .where((d) {
          final dt = DateTime.parse(d['delivered_at']).toLocal();
          return dt.isAfter(startOfDay) && d['dose_type'] != 'Basal';
        })
        .fold(0.0, (s, d) => s + (d['units'] as num).toDouble());
  }

  /// Most recent basal dose as a proxy for current basal rate
  String get _currentBasalRate {
    final basalDoses = _insulinDoses
        .where((d) => d['dose_type'] == 'Basal')
        .toList();
    if (basalDoses.isEmpty) return '—';
    basalDoses.sort(
      (a, b) => DateTime.parse(
        b['delivered_at'],
      ).compareTo(DateTime.parse(a['delivered_at'])),
    );
    final units = (basalDoses.first['units'] as num).toDouble();
    return '${units.toStringAsFixed(2)} U/h';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientData() async {
    try {
      // Fetch profile including age from users join and profile picture
      final profile = await supabase
          .from('patient_profile')
          .select('*, users(full_name, age, profile_picture_url)')
          .eq('id', widget.patientId)
          .single();

      final userId = profile['user_id'] as String;
      
      // Get profile picture URL from users table
      final userData = profile['users'] as Map<String, dynamic>?;
      _profilePictureUrl = userData?['profile_picture_url'] as String?;

      final results = await Future.wait([
        supabase
            .from('care_plans')
            .select()
            .eq('patient_id', widget.patientId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        supabase
            .from('glucose_readings')
            .select()
            .eq('patient_id', widget.patientId)
            .order('recorded_at', ascending: true),
        supabase
            .from('insulin_doses')
            .select()
            .eq('patient_id', widget.patientId)
            .order('delivered_at', ascending: true),
        supabase
            .from('alerts')
            .select()
            .eq('patient_id', widget.patientId)
            .order('triggered_at', ascending: false)
            .limit(5),
        supabase
            .from('devices')
            .select()
            .eq('patient_id', userId)
            .eq('is_active', true)
            .maybeSingle(),
        // ✅ FIXED: Latest AI prediction - use patient_uuid instead of patient_id
        supabase
            .from('ai_predictions')
            .select()
            .eq('patient_uuid', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        // Latest IOB snapshot
        supabase
            .from('insulin_on_board')
            .select()
            .eq('patient_id', widget.patientId)
            .order('calculated_at', ascending: false)
            .limit(1)
            .maybeSingle(),
      ]);

      if (!mounted) return;
      setState(() {
        _patientProfile = profile;
        _carePlan = results[0] as Map<String, dynamic>?;
        _glucoseReadings = (results[1] as List).cast<Map<String, dynamic>>();
        _insulinDoses = (results[2] as List).cast<Map<String, dynamic>>();
        _alerts = (results[3] as List).cast<Map<String, dynamic>>();
        _device = results[4] as Map<String, dynamic>?;
        _latestPrediction = results[5] as Map<String, dynamic>?;
        _latestIob = results[6] as Map<String, dynamic>?;
        // ✅ Increment key to force rebuild of care plan card
        _carePlanReloadKey++;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching patient data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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
    // Format patient ID as #PT-XXXXX (zero-padded to 5 digits)
    final formattedId = '#PT-${widget.patientId.toString().padLeft(5, '0')}';
    return AppBar(
      backgroundColor: colors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            widget.patientName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          TranslatedText(
            'Patient ID: $formattedId',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
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
          icon: const Icon(Icons.location_on_outlined),
          onPressed: () => _openLocationView(context),
          tooltip: 'Location',
        ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  void _openLocationView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: context.colors.primaryDark,
            foregroundColor: Colors.white,
            title: TranslatedText('${widget.patientName} — Location'),
          ),
          body: OrientationBuilder(
            builder: (ctx, orientation) => LocationView(
              patient: LocationPatientInfo(
                patientUserId: _patientProfile!['user_id'] as String,
                fullName: widget.patientName,
              ),
              isLandscape: orientation == Orientation.landscape,
              userRole: 'doctor',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    final colors = context.colors;
    // Age: prefer users.age, fallback to patient_profile.age
    final usersMap = _patientProfile?['users'] as Map<String, dynamic>?;
    final age =
        (usersMap?['age'] ?? _patientProfile?['age'])?.toString() ?? '—';
    final gender = _patientProfile?['gender'] ?? '—';
    final name = widget.patientName;
    final userId = _patientProfile?['user_id'] as String? ?? '';

    final latest = _glucoseReadings.isNotEmpty ? _glucoseReadings.last : null;
    final latestValue = latest != null
        ? (latest['value_mg_dl'] as num).toInt().toString()
        : '—';
    final trend = latest?['trend'] as String? ?? 'stable';
    final trendIcon = trend == 'up'
        ? Icons.trending_up
        : trend == 'down'
        ? Icons.trending_down
        : Icons.trending_flat;

    return Container(
      color: colors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        children: [
          ProfilePicture(
            userId: userId,
            imageUrl: _profilePictureUrl,
            size: 52,
            isEditable: false,
            showInitials: true,
            displayName: name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Age $age • $gender • Type 1 Diabetes',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _headerChip(
                      Icons.bluetooth,
                      'CGM Online',
                      Colors.greenAccent,
                    ),
                    const SizedBox(width: 8),
                    _headerChip(
                      Icons.water_drop_outlined,
                      'Pump Active',
                      Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildLiveGlucoseChip(latestValue, trendIcon),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        TranslatedText(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveGlucoseChip(String value, IconData trendIcon) {
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
              TranslatedText(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(trendIcon, color: Colors.greenAccent, size: 14),
                  const TranslatedText(
                    'mg/dL',
                    style: TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          const TranslatedText(
            'LIVE',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
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
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
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
        label: const TranslatedText(
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
            const TranslatedText(
              'Remove Patient',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: colors.textPrimary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Are you sure you want to remove '),
              TextSpan(
                text: widget.patientName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text:
                    ' from your patient list?\n\nThis will disconnect them from your care and cannot be undone.',
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
                      side: BorderSide(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const TranslatedText(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      
                      if (mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      try {
                        final currentUserId = supabase.auth.currentUser!.id;
                        
                        final patientProfile = await supabase
                            .from('patient_profile')
                            .select('user_id')
                            .eq('id', widget.patientId)
                            .single();
                        
                        final patientUserId = patientProfile['user_id'] as String;
                        
                        await supabase
                            .from('doctor_patient_connections')
                            .delete()
                            .eq('doctor_id', currentUserId)
                            .eq('patient_id', patientUserId);
                        
                        if (mounted) Navigator.pop(context);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: TranslatedText('Patient removed successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        print('Error removing patient: $e');
                        
                        if (mounted) Navigator.pop(context);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: TranslatedText(
                                'Failed to remove patient. Please try again.',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const TranslatedText(
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
    final values = _glucoseReadings
        .map((r) => (r['value_mg_dl'] as num).toDouble())
        .toList();

    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    final gmi = values.isEmpty ? 0.0 : 3.31 + 0.02392 * avg;

    double cv = 0;
    if (values.length > 1) {
      final mean = avg;
      final variance =
          values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
          values.length;
      cv = (math.sqrt(variance) / mean) * 100;
    }

    final inRange = values.isEmpty
        ? 0
        : (values.where((v) => v >= 70 && v <= 180).length /
                  values.length *
                  100)
              .round();

    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            'Average\nGlucose',
            avg.toStringAsFixed(0),
            'mg/dL',
            colors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            'GMI\nEst. A1C',
            gmi.toStringAsFixed(1),
            '%',
            const Color(0xFF5B8CF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            'Glucose\nVariability',
            cv.toStringAsFixed(0),
            'CV%',
            colors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            'Time\nIn Range',
            '$inRange',
            '%',
            const Color(0xFF6FCF97),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TranslatedText(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          TranslatedText(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TranslatedText(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInRangeCard(BuildContext context) {
    final values = _glucoseReadings
        .map((r) => (r['value_mg_dl'] as num).toDouble())
        .toList();
    final total = values.length;

    int pct(bool Function(double) test) =>
        total == 0 ? 0 : (values.where(test).length / total * 100).round();

    final veryHigh = pct((v) => v > 250);
    final high = pct((v) => v > 180 && v <= 250);
    final inRange = pct((v) => v >= 70 && v <= 180);
    final low = pct((v) => v >= 54 && v < 70);
    final veryLow = pct((v) => v < 54);

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
                    _tirRow(
                      'Very High (>250)',
                      veryHigh,
                      const Color(0xFFD32F2F),
                    ),
                    const SizedBox(height: 6),
                    _tirRow('High (181–250)', high, const Color(0xFFFF9F40)),
                    const SizedBox(height: 6),
                    _tirRow(
                      'In Range (70–180)',
                      inRange,
                      const Color(0xFF2BB6A3),
                    ),
                    const SizedBox(height: 6),
                    _tirRow('Low (54–69)', low, const Color(0xFFFBC02D)),
                    const SizedBox(height: 6),
                    _tirRow('Very Low (<54)', veryLow, const Color(0xFFB71C1C)),
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
                      TIRSegment(
                        percent: veryHigh.toDouble(),
                        color: const Color(0xFFD32F2F),
                      ),
                      TIRSegment(
                        percent: high.toDouble(),
                        color: const Color(0xFFFF9F40),
                      ),
                      TIRSegment(
                        percent: inRange.toDouble(),
                        color: const Color(0xFF2BB6A3),
                      ),
                      TIRSegment(
                        percent: low.toDouble(),
                        color: const Color(0xFFFBC02D),
                      ),
                      TIRSegment(
                        percent: veryLow.toDouble(),
                        color: const Color(0xFFB71C1C),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TranslatedText(
                          '$inRange%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2BB6A3),
                          ),
                        ),
                        const TranslatedText(
                          'TIR',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
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
                _tirBar(veryHigh.toDouble(), const Color(0xFFD32F2F)),
                _tirBar(high.toDouble(), const Color(0xFFFF9F40)),
                _tirBar(inRange.toDouble(), const Color(0xFF2BB6A3)),
                _tirBar(low.toDouble(), const Color(0xFFFBC02D)),
                _tirBar(veryLow.toDouble(), const Color(0xFFB71C1C)),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TranslatedText(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
        TranslatedText(
          '$percent%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _tirBar(double percent, Color color) {
    final flex = percent.toInt().clamp(1, 100);
    return Flexible(
      flex: flex,
      child: Container(height: 10, color: color),
    );
  }

  Widget _buildPumpStatusCard(BuildContext context) {
    final colors = context.colors;

    final deviceName = _device?['device_name'] as String? ?? 'Pump';
    final batteryRaw = _device?['battery_health'] as String? ?? '—';
    final lastSyncAt = _device?['last_sync_at'] as String?;
    final lastSyncDisplay = lastSyncAt != null ? _timeAgo(lastSyncAt) : '—';
    final isActive = _device?['is_active'] as bool? ?? false;

    final tdd = _tddToday;
    final basalToday = _basalToday;
    final bolusToday = _bolusToday;
    final autoCount = insulinLog.where((d) => d.source == 'AID Auto').length;

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
                    TranslatedText(
                      deviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    TranslatedText(
                      'Last sync: $lastSyncDisplay',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                context,
                isActive ? 'Active' : 'Inactive',
                isActive ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _pumpStat(
                  'Battery',
                  batteryRaw,
                  'Device battery',
                  const Color(0xFF6FCF97),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pumpStat(
                  'Auto Doses',
                  '$autoCount',
                  'AID-delivered',
                  const Color(0xFF5B8CF5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pumpStat(
                  'Basal Rate',
                  _currentBasalRate,
                  'Last recorded',
                  colors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _pumpStat(
                  'Total Daily\nDose',
                  '${tdd.toStringAsFixed(1)} U',
                  'Today so far',
                  colors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pumpStat(
                  'Basal Today',
                  '${basalToday.toStringAsFixed(1)} U',
                  'Delivered',
                  Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pumpStat(
                  'Bolus Today',
                  '${bolusToday.toStringAsFixed(1)} U',
                  'Delivered',
                  const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pumpStat(String label, String value, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        TranslatedText(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 1),
        TranslatedText(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIDStatusCard(BuildContext context) {
    final colors = context.colors;

    final predictedValue = _latestPrediction?['predicted_value_mg_dl'];
    final predictedDisplay = predictedValue != null
        ? '${(predictedValue as num).toStringAsFixed(0)} mg/dL'
        : '—';
    final horizon = _latestPrediction?['horizon_minutes'];
    final horizonDisplay = horizon != null
        ? '${(horizon as num).toInt()} min'
        : '—';
    final riskLevel = _latestPrediction?['risk_level'] as String? ?? '—';
    final modelVersion = _latestPrediction?['model_version'] as String? ?? '—';

    final isf = _carePlan?['insulin_sensitivity_factor'] as String? ?? '—';
    final carbRatio = _carePlan?['carb_ratio'];
    final carbRatioDisplay = carbRatio != null
        ? '1 U : ${(carbRatio as num).toStringAsFixed(0)}g carbs'
        : '—';
    final aidEnabled = _carePlan?['aid_mode_enabled'] as bool? ?? false;

    final latestReading = _glucoseReadings.isNotEmpty
        ? _glucoseReadings.last
        : null;
    final trend = latestReading?['trend'] as String? ?? 'stable';
    final trendDisplay = trend == 'up'
        ? '↗ Rising slowly'
        : trend == 'down'
        ? '↘ Falling slowly'
        : '→ Stable';

    Color riskColor;
    if (riskLevel == 'high') {
      riskColor = colors.error;
    } else if (riskLevel == 'medium') {
      riskColor = colors.warning;
    } else {
      riskColor = colors.success;
    }

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
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF5B8CF5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TranslatedText(
                      'AI-Powered AID System',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    TranslatedText(
                      'Model: $modelVersion • ${aidEnabled ? 'Adaptive mode' : 'Manual mode'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                context,
                aidEnabled ? 'AUTO' : 'OFF',
                aidEnabled ? const Color(0xFF5B8CF5) : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _aidRow(
            Icons.show_chart,
            'Predicted Glucose ($horizonDisplay)',
            predictedDisplay,
            colors.textPrimary,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(
            Icons.trending_up,
            'Current Glucose Trend',
            trendDisplay,
            colors.accent,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(
            Icons.warning_amber_rounded,
            'Risk Level',
            riskLevel.toUpperCase(),
            riskColor,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(
            Icons.tune,
            'Insulin Sensitivity Factor',
            isf.isNotEmpty && isf != '—' ? '1 U : $isf mg/dL' : '—',
            Colors.blueGrey,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _aidRow(
            Icons.rice_bowl_outlined,
            'Insulin-to-Carb Ratio',
            carbRatioDisplay,
            Colors.blueGrey,
          ),
          if (_latestPrediction != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    riskLevel == 'low'
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: riskColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      riskLevel == 'low'
                          ? 'AID system is performing well. Risk level is low.'
                          : 'Risk level is ${riskLevel.toUpperCase()}. Monitor closely.',
                      style: TextStyle(fontSize: 12, color: riskColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          Expanded(
            child: TranslatedText(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          TranslatedText(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(BuildContext context) {
    if (_alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(context),
        child: const Center(
          child: TranslatedText('No recent alerts', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: _alerts.asMap().entries.map((entry) {
          final i = entry.key;
          final alert = entry.value;
          final type = alert['alert_type'] as String? ?? '';
          final title = alert['title'] as String? ?? type.toUpperCase();
          final message = alert['message'] as String? ?? '';
          final dt = DateTime.parse(alert['triggered_at']).toLocal();
          final hour = dt.hour > 12
              ? dt.hour - 12
              : dt.hour == 0
              ? 12
              : dt.hour;
          final min = dt.minute.toString().padLeft(2, '0');
          final period = dt.hour < 12 ? 'AM' : 'PM';
          final time = '$hour:$min $period';

          IconData icon;
          Color color;
          if (type.contains('high')) {
            icon = Icons.warning_amber_rounded;
            color = context.colors.warning;
          } else if (type.contains('low')) {
            icon = Icons.arrow_downward_rounded;
            color = const Color(0xFFFBC02D);
          } else {
            icon = Icons.check_circle_outline;
            color = context.colors.success;
          }

          return Column(
            children: [
              if (i > 0) const Divider(height: 20),
              _alertRow(icon, title, message, color, time),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _alertRow(
    IconData icon,
    String tag,
    String message,
    Color color,
    String time,
  ) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TranslatedText(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TranslatedText(
                    time,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TranslatedText(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: Added key to force rebuild when care plan updates
  Widget _buildCarePlanCard(BuildContext context) {
    final colors = context.colors;
    final plan = _carePlan;

    final targetMin = plan?['target_glucose_min']?.toString() ?? '70';
    final targetMax = plan?['target_glucose_max']?.toString() ?? '180';
    final insulinType = plan?['insulin_type'] ?? '—';
    final maxDose = plan?['max_auto_dose_units']?.toString() ?? '—';
    final notes = plan?['notes'] ?? '—';
    final nextAppt = plan?['next_appointment'] as String?;
    String apptDisplay = '—';
    if (nextAppt != null) {
      final dt = DateTime.tryParse(nextAppt);
      if (dt != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        apptDisplay = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    }

    return Container(
      // ✅ Key forces Flutter to rebuild this widget when key changes
      key: ValueKey(_carePlanReloadKey),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _carePlanRow('Target Range', '$targetMin – $targetMax mg/dL', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Insulin Type', insulinType, context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Max Auto-Bolus', '$maxDose U per event', context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Notes', notes, context),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _carePlanRow('Next Appointment', apptDisplay, context),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarePlanEditorScreen(
                      patientName: widget.patientName,
                      patientId: widget.patientId,
                      existingPlan: _carePlan,
                    ),
                  ),
                );
                if (updated == true) {
                  await _fetchPatientData();
                }
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: const TranslatedText(
                'Edit Care Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            child: TranslatedText(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TranslatedText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
                  child: glucoseHistory.length < 2
                      ? const Center(
                          child: TranslatedText(
                            'Not enough data',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : CustomPaint(
                          size: const Size(double.infinity, 220),
                          painter: GlucoseChartPainter(
                            readings: glucoseHistory,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['12am', '6am', '12pm', '6pm', '12am']
                      .map(
                        (t) => TranslatedText(
                          t,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      )
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
                _cgmRow('Device', _device?['device_name'] ?? '—', context),
                _cgmRow('Type', _device?['device_type'] ?? '—', context),
                _cgmRow(
                  'Firmware',
                  _device?['firmware_version'] ?? '—',
                  context,
                ),
                _cgmRow('Battery', _device?['battery_health'] ?? '—', context),
                _cgmRow(
                  'Last Sync',
                  _device?['last_sync_at'] != null
                      ? _timeAgo(_device!['last_sync_at'] as String)
                      : '—',
                  context,
                ),
                _cgmRow(
                  'Status',
                  _device?['is_active'] == true ? 'Active' : 'Inactive',
                  context,
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
          _sectionTitle(context, 'Recent Readings (Last 12)'),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(context),
            child: glucoseHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: TranslatedText(
                        'No readings available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: math.min(12, glucoseHistory.length),
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
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

  String _timeAgo(String isoString) {
    final diff = DateTime.now().difference(DateTime.parse(isoString).toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
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
          child: TranslatedText(
            '${reading.value}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor,
              fontSize: 13,
            ),
          ),
        ),
      ),
      title: TranslatedText(
        '${reading.time}  •  $status',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: reading.mealTag != null
          ? Row(
              children: [
                const Icon(Icons.restaurant, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                TranslatedText(
                  reading.mealTag!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            )
          : const TranslatedText(
              'CGM reading',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
      trailing: TranslatedText(
        'mg/dL',
        style: TextStyle(fontSize: 10, color: colors.textSecondary),
      ),
    );
  }

  Widget _cgmRow(String label, String value, BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: TranslatedText(
              label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: TranslatedText(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        TranslatedText(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInsulinTab(BuildContext context) {
    final colors = context.colors;
    final totalBolus = insulinLog
        .where((d) => d.type != 'Basal')
        .fold(0.0, (s, d) => s + d.units);
    final totalBasal = insulinLog
        .where((d) => d.type == 'Basal')
        .fold(0.0, (s, d) => s + d.units);

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
              Expanded(
                child: _statCard(
                  context,
                  'Total\nBolus',
                  totalBolus.toStringAsFixed(1),
                  'units',
                  colors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  context,
                  'Total\nBasal',
                  totalBasal.toStringAsFixed(1),
                  'units',
                  const Color(0xFF5B8CF5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  context,
                  'Total\nDelivered',
                  (totalBolus + totalBasal).toStringAsFixed(1),
                  'units',
                  colors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  context,
                  'Auto\nDoses',
                  insulinLog
                      .where((d) => d.source == 'AID Auto')
                      .length
                      .toString(),
                  'by AID',
                  const Color(0xFF6FCF97),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Dose Log'),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(context),
            child: insulinLog.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: TranslatedText(
                        'No insulin doses recorded',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: insulinLog.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) =>
                        _insulinLogTile(insulinLog[i], context),
                  ),
          ),
          const SizedBox(height: 36),
          _sectionTitle(context, 'Active Insulin on Board (IOB)'),
          const SizedBox(height: 12),
          _buildIobCard(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildIobCard(BuildContext context) {
    final colors = context.colors;
    final iob = _latestIob;

    final totalIob = iob?['total_iob_units'];
    final iobDisplay = totalIob != null
        ? '${(totalIob as num).toStringAsFixed(1)} U'
        : '—';
    final dia = iob?['dia_minutes'];
    final diaDisplay = dia != null
        ? '${((dia as num) / 60).toStringAsFixed(0)}h'
        : '—';
    final expiresAt = iob?['expires_at'] as String?;
    String expiryDisplay = '—';
    if (expiresAt != null) {
      final dt = DateTime.tryParse(expiresAt)?.toLocal();
      if (dt != null) {
        final h = dt.hour > 12
            ? dt.hour - 12
            : dt.hour == 0
            ? 12
            : dt.hour;
        final m = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour < 12 ? 'AM' : 'PM';
        expiryDisplay = '$h:$m $period';
      }
    }
    final decayModel = iob?['decay_model'] as String? ?? '—';
    final doseCount = iob?['contributing_dose_count'];
    final doseCountDisplay = doseCount != null
        ? '${(doseCount as num).toInt()} recent doses'
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TranslatedText(
                iobDisplay,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5B8CF5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Insulin on Board',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    TranslatedText(
                      'Based on $doseCountDisplay',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (diaDisplay != '—')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8CF5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TranslatedText(
                    'DIA: $diaDisplay',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B8CF5),
                    ),
                  ),
                ),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 16),
            TranslatedText(
              'IOB decays to 0 around $expiryDisplay. Model: $decayModel. AID will account for active insulin before issuing next auto-bolus.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 16),
            TranslatedText(
              'No active IOB data available.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
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
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(typeIcon, color: typeColor, size: 18),
      ),
      title: Row(
        children: [
          TranslatedText(
            '${dose.units} U  •  ${dose.type}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: dose.source == 'AID Auto'
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TranslatedText(
              dose.source,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: dose.source == 'AID Auto'
                    ? Colors.green
                    : colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      subtitle: TranslatedText(
        '${dose.time}  •  ${dose.reason}',
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return TranslatedText(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
        letterSpacing: -0.3,
        height: 1.0,
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = context.colors;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 3),
        ),
      ],
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
  InsulinDose({
    required this.time,
    required this.type,
    required this.units,
    required this.reason,
    required this.source,
  });
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
      return size.height -
          ((val - minGlucose) / (maxGlucose - minGlucose)) * size.height;
    }

    final rangePaint = Paint()
      ..color = const Color(0xFF2BB6A3).withValues(alpha: 0.07);
    canvas.drawRect(
      Rect.fromLTRB(0, toY(targetHigh), size.width, toY(targetLow)),
      rangePaint,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF2BB6A3).withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(0, toY(targetHigh)),
      Offset(size.width, toY(targetHigh)),
      linePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, toY(targetLow)),
      Offset(size.width, toY(targetLow)),
      linePaint,
    );

    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < readings.length; i++) {
      final x = i * xStep;
      final y = toY(readings[i].value.toDouble());
      if (i == 0) {
        fillPath.lineTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((readings.length - 1) * xStep, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2BB6A3).withValues(alpha: 0.2),
        const Color(0xFF2BB6A3).withValues(alpha: 0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
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
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, curvePaint);

    for (int i = 0; i < readings.length; i++) {
      if (readings[i].mealTag != null) {
        final x = i * xStep;
        final y = toY(readings[i].value.toDouble());
        final markerPaint = Paint()..color = const Color(0xFFFF9F40);
        canvas.drawCircle(Offset(x, y), 5, markerPaint);
        canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
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