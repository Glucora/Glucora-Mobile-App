// guardian_patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'guardian_patient_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

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
  
  // Real-time data streams
  late final Stream<List<Map<String, dynamic>>> _glucoseStream;
  late final Stream<Map<String, dynamic>> _devicesStream;
  late final Stream<Map<String, dynamic>> _todayStatsStream;
  late final Stream<Map<String, dynamic>> _carePlanStream;
  late final Stream<Map<String, dynamic>> _locationStream;
  
  // Cached data
  Map<String, dynamic>? _latestGlucose;
  Map<String, dynamic>? _devicesData;
  Map<String, dynamic>? _todayStats;
  Map<String, dynamic>? _carePlan;
  Map<String, dynamic>? _locationData;
  Map<String, dynamic>? _doctorInfo;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _initializeRealtimeSubscriptions();
  }

  void _initializeRealtimeSubscriptions() {
    final supabase = Supabase.instance.client;
    final patientId = widget.patient.id;
    
    // Subscribe to glucose readings (realtime)
    supabase
        .channel('glucose_changes_${widget.patient.id}')
        .on(
            PostgresChangesEvent(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'glucose_readings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'patient_id',
                value: patientId.toString(),
              ),
            ),
            (payload) => _fetchLatestGlucose())
        .subscribe();
    
    // Fetch initial data
    _fetchLatestGlucose();
    _fetchDevices();
    _fetchTodayStats();
    _fetchCarePlan();
    _fetchLocation();
    _fetchDoctorInfo();
  }

  Future<void> _fetchLatestGlucose() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('glucose_readings')
        .select()
        .eq('patient_id', widget.patient.id)
        .order('recorded_at', ascending: false)
        .limit(1);
    
    if (response.isNotEmpty && mounted) {
      setState(() {
        _latestGlucose = response.first;
      });
    }
  }

  Future<void> _fetchDevices() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('devices')
        .select()
        .eq('patient_id', widget.patient.userId) // Assuming patient.userId is the UUID
        .eq('is_active', true);
    
    if (mounted) {
      setState(() {
        _devicesData = {
          'sensor_connected': response.any((d) => d['device_type'] == 'cgm' && d['is_active'] == true),
          'pump_active': response.any((d) => d['device_type'] == 'pump' && d['is_active'] == true),
        };
      });
    }
  }

  Future<void> _fetchTodayStats() async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    // Fetch today's insulin doses
    final doses = await supabase
        .from('insulin_doses')
        .select()
        .eq('patient_id', widget.patient.id)
        .gte('delivered_at', startOfDay.toIso8601String());
    
    // Fetch latest IOB
    final iob = await supabase
        .from('insulin_on_board')
        .select()
        .eq('patient_id', widget.patient.id)
        .order('calculated_at', ascending: false)
        .limit(1);
    
    final totalUnits = doses.fold(0.0, (sum, dose) => sum + (dose['units'] as num).toDouble());
    final autoDoses = doses.where((d) => d['delivery_method'] == 'Pump').length;
    final manualDoses = doses.where((d) => d['delivery_method'] != 'Pump').length;
    
    if (mounted) {
      setState(() {
        _todayStats = {
          'doses_today': doses.length,
          'total_units': totalUnits,
          'all_automatic': manualDoses == 0,
          'iob_units': iob.isNotEmpty ? iob.first['total_iob_units'] : 0.0,
        };
      });
    }
  }

  Future<void> _fetchCarePlan() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('care_plans')
        .select()
        .eq('patient_id', widget.patient.id)
        .order('created_at', ascending: false)
        .limit(1);
    
    if (response.isNotEmpty && mounted) {
      setState(() {
        _carePlan = response.first;
      });
    }
  }

  Future<void> _fetchLocation() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('patient_locations')
        .select()
        .eq('patient_id', widget.patient.id)
        .eq('sharing_enabled', true)
        .order('recorded_at', ascending: false)
        .limit(1);
    
    if (response.isNotEmpty && mounted) {
      setState(() {
        _locationData = response.first;
      });
    }
  }

  Future<void> _fetchDoctorInfo() async {
    final supabase = Supabase.instance.client;
    if (_carePlan != null && _carePlan!['doctor_id'] != null) {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', _carePlan!['doctor_id'])
          .limit(1);
      
      if (response.isNotEmpty && mounted) {
        setState(() {
          _doctorInfo = response.first;
        });
      }
    }
  }

  // Helper to get dynamic patient data
  GuardianPatient _getUpdatedPatient() {
    return widget.patient.copyWith(
      glucoseValue: _latestGlucose != null 
          ? (_latestGlucose!['value_mg_dl'] as num).toDouble()
          : widget.patient.glucoseValue,
      glucoseLabel: _getGlucoseLabel(_latestGlucose?['value_mg_dl']),
      glucoseTrend: _getGlucoseTrend(_latestGlucose?['trend']),
      sensorConnected: _devicesData?['sensor_connected'] ?? widget.patient.sensorConnected,
      pumpActive: _devicesData?['pump_active'] ?? widget.patient.pumpActive,
      dosesToday: _todayStats?['doses_today'] ?? widget.patient.dosesToday,
      allDosesAutomatic: _todayStats?['all_automatic'] ?? widget.patient.allDosesAutomatic,
      lastSeenTime: _formatLastSeen(_locationData?['recorded_at']),
    );
  }

  String _getGlucoseLabel(dynamic value) {
    if (value == null) return 'Unknown';
    final numValue = (value as num).toDouble();
    if (numValue < 70) return 'Too low';
    if (numValue < 80) return 'A bit low';
    if (numValue <= 180) return 'In Range';
    if (numValue <= 250) return 'A bit high';
    if (numValue <= 300) return 'Too high';
    return 'Very high';
  }

  String _getGlucoseTrend(String? trend) {
    switch (trend) {
      case 'DoubleUp': return 'up';
      case 'SingleUp': return 'up';
      case 'FortyFiveUp': return 'up';
      case 'Flat': return 'flat';
      case 'FortyFiveDown': return 'down';
      case 'SingleDown': return 'down';
      case 'DoubleDown': return 'down';
      default: return 'flat';
    }
  }

  String _formatLastSeen(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    final time = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _call() {
    HapticFeedback.mediumImpact();
    // TODO: Implement actual calling functionality
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Calling ${widget.patient.name}...',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF2A9D8F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _sms() {
    // TODO: Implement actual SMS functionality
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening SMS for ${widget.patient.name}...',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE76F51),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() { 
    _tab.dispose();
    // Remove Supabase channel subscription
    Supabase.instance.client.removeChannel('glucose_changes_${widget.patient.id}');
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final patient = _getUpdatedPatient();
    final sColor = statusColor(patient.overallStatus, colors);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(builder: (ctx, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return Column(children: [

            Container(
              color: colors.surface,
              padding: EdgeInsets.fromLTRB(8, isLandscape ? 8 : 14, 16, isLandscape ? 8 : 14),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: colors.textPrimary,
                ),
                CircleAvatar(
                  radius: isLandscape ? 18 : 22,
                  backgroundColor: sColor.withValues(alpha: 0.12),
                  child: Text(patient.name.substring(0, 1),
                      style: TextStyle(color: sColor, fontWeight: FontWeight.w800,
                          fontSize: isLandscape ? 14 : 16)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(patient.name, style: TextStyle(
                      fontSize: isLandscape ? 15 : 18,
                      fontWeight: FontWeight.w800, color: colors.textPrimary)),
                  Text('${patient.relationship}  ·  Age ${patient.age}  ·  Type 1',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patient.overallStatus == 'emergency' ? 'Needs help now'
                        : patient.overallStatus == 'attention' ? 'Needs attention' : 'Doing well',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sColor),
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
                    child: Icon(Icons.sms_rounded, color: colors.warning, size: 19),
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
                    child: Icon(Icons.call_rounded, color: colors.accent, size: 19),
                  ),
                ),
              ]),
            ),

            Container(
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.textSecondary.withValues(alpha: 0.2)))),
              child: TabBar(
                controller: _tab,
                labelColor: colors.accent,
                unselectedLabelColor: colors.textSecondary,
                indicatorColor: colors.accent,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [Tab(text: 'Overview'), Tab(text: 'Location'), Tab(text: 'Doctor Plan')],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const ClampingScrollPhysics(),
                children: [
                  _OverviewTab(
                    patient: patient, 
                    isLandscape: isLandscape,
                    carePlan: _carePlan,
                    iobUnits: _todayStats?['iob_units'],
                  ),
                  _LocationTab(
                    patient: patient, 
                    isLandscape: isLandscape,
                    locationData: _locationData,
                  ),
                  _DoctorPlanTab(
                    patient: patient, 
                    isLandscape: isLandscape,
                    carePlan: _carePlan,
                    doctorInfo: _doctorInfo,
                  ),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }

  static Color statusColor(String s, GlucoraColors colors) {
    switch (s) {
      case 'emergency': return colors.error;
      case 'attention': return colors.warning;
      default:          return colors.accent;
    }
  }

  static Color glucoseColor(GuardianPatient p, GlucoraColors colors) {
    switch (p.glucoseLabel) {
      case 'Too high': case 'Very high': case 'Too low': case 'Very low':
        return colors.error;
      case 'A bit high': return colors.warning;
      default:           return colors.accent;
    }
  }
}

// Update Overview Tab to accept carePlan and iobUnits
class _OverviewTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  final Map<String, dynamic>? carePlan;
  final double? iobUnits;
  
  const _OverviewTab({
    required this.patient, 
    required this.isLandscape,
    this.carePlan,
    this.iobUnits,
  });

  Color gColor(BuildContext context) {
    final colors = context.colors;
    return _GuardianPatientDetailScreenState.glucoseColor(patient, colors);
  }

  IconData get tIcon {
    switch (patient.glucoseTrend) {
      case 'up':   return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default:     return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glucoseColorVal = gColor(context);
    final targetMin = carePlan?['target_glucose_min'] ?? 70;
    final targetMax = carePlan?['target_glucose_max'] ?? 180;
    
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: isLandscape
              ? SliverToBoxAdapter(child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: [
                      _glucoseCard(context, targetMin, targetMax),
                      const SizedBox(height: 14),
                      _devicesCard(context),
                    ])),
                    const SizedBox(width: 14),
                    Expanded(child: Column(children: [
                      _insulinCard(context),
                      const SizedBox(height: 14),
                      _todayCard(context),
                    ])),
                  ],
                ))
              : SliverList(delegate: SliverChildListDelegate([
                  _glucoseCard(context, targetMin, targetMax),
                  const SizedBox(height: 14),
                  _devicesCard(context),
                  const SizedBox(height: 14),
                  _insulinCard(context),
                  const SizedBox(height: 14),
                  _todayCard(context),
                ])),
        ),
      ],
    );
  }

  Widget _glucoseCard(BuildContext context, double targetMin, double targetMax) {
    final colors = context.colors;
    final glucoseColorVal = gColor(context);
    return _card(context, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel(context, 'Blood Sugar Right Now'),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${patient.glucoseValue.toInt()}',
            style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900,
                color: glucoseColorVal, letterSpacing: -2, height: 1)),
        const SizedBox(width: 6),
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text('mg/dL', style: TextStyle(fontSize: 13,
                color: colors.textSecondary, fontWeight: FontWeight.w500))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: glucoseColorVal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Icon(tIcon, color: glucoseColorVal, size: 14),
            const SizedBox(width: 5),
            Text(patient.glucoseLabel,
                style: TextStyle(color: glucoseColorVal, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      _rangeBar(context, targetMin, targetMax),
    ]));
  }

  Widget _rangeBar(BuildContext context, double targetMin, double targetMax) {
    final colors = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Too Low', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
        Text('Normal Range', style: TextStyle(fontSize: 10, color: colors.accent, fontWeight: FontWeight.w600)),
        Text('Too High', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(height: 10, child: Row(children: [
          Expanded(flex: (targetMin - 40).toInt(), child: Container(color: colors.error.withValues(alpha: 0.3))),
          Expanded(flex: (targetMax - targetMin).toInt(), child: Container(color: colors.accent.withValues(alpha: 0.25))),
          Expanded(flex: (300 - targetMax).toInt(), child: Container(color: colors.warning.withValues(alpha: 0.3))),
        ])),
      ),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (ctx, constraints) {
        const double minV = 40, maxV = 300;
        final double pct = ((patient.glucoseValue - minV) / (maxV - minV)).clamp(0.0, 1.0);
        final glucoseColorVal = gColor(context);
        return Stack(children: [
          const SizedBox(height: 14, width: double.infinity),
          Positioned(
            left: (constraints.maxWidth * pct - 6).clamp(0.0, constraints.maxWidth - 12),
            child: Icon(Icons.arrow_drop_up_rounded, color: glucoseColorVal, size: 20),
          ),
        ]);
      }),
    ]);
  }

  Widget _devicesCard(BuildContext context) {
    final colors = context.colors;
    return _card(context, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel(context, 'Devices'),
      const SizedBox(height: 12),
      _deviceRow(context, Icons.sensors, 'Sugar Sensor',
          patient.sensorConnected ? 'Connected' : 'Disconnected', patient.sensorConnected),
      const SizedBox(height: 8),
      _deviceRow(context, Icons.water_drop_outlined, 'Insulin Pump',
          patient.pumpActive ? 'Working' : 'Paused', patient.pumpActive),
    ]));
  }

  Widget _deviceRow(BuildContext context, IconData icon, String label, String status, bool ok) {
    final colors = context.colors;
    final color = ok ? colors.accent : colors.error;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }

  Widget _insulinCard(BuildContext context) {
    final colors = context.colors;
    final totalUnits = (patient.dosesToday * 2.5).toStringAsFixed(1); // Example calculation
    return _card(context, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel(context, 'Insulin Today'),
      const SizedBox(height: 12),
      Row(children: [
        _stat(colors, '${patient.dosesToday}', 'Doses given'),
        _divider(context),
        _stat(colors, patient.allDosesAutomatic ? 'Auto' : 'Manual', 'How given'),
        _divider(context),
        _stat(colors, '${iobUnits?.toStringAsFixed(1) ?? '0.0'} U', 'Active insulin'),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: colors.accent, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(
            patient.allDosesAutomatic
                ? 'The device handled everything automatically today.'
                : 'Some doses were given manually today.',
            style: TextStyle(fontSize: 12, color: colors.accent, height: 1.4, fontWeight: FontWeight.w500),
          )),
        ]),
      ),
    ]));
  }

  Widget _stat(GlucoraColors colors, String val, String label) => Expanded(child: Column(children: [
    Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
    const SizedBox(height: 2),
    Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: colors.textSecondary, height: 1.3)),
  ]));

  Widget _divider(BuildContext context) {
    final colors = context.colors;
    return Container(height: 36, width: 1, color: colors.textSecondary.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _todayCard(BuildContext context) {
    final colors = context.colors;
    return _card(context, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel(context, 'Today at a Glance'),
      const SizedBox(height: 12),
      _story(context, 'Morning',  'Sugar was in the safe zone when ${patient.name} woke up', true),
      _story(context, 'Breakfast', 'Ate breakfast, device gave insulin automatically', true),
      _story(context, 'Midday',   'Sugar stayed in the normal range', true),
      _story(context, 'Now',      patient.glucoseLabel == 'In Range'
          ? 'Doing well — sugar is in the normal range'
          : 'Sugar is ${patient.glucoseLabel.toLowerCase()} — device is managing it',
          patient.glucoseLabel == 'In Range'),
    ]));
  }

  Widget _story(BuildContext context, String time, String text, bool ok) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: ok ? colors.accent : colors.warning,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: RichText(text: TextSpan(children: [
          TextSpan(text: '$time  ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          TextSpan(text: text,
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
        ]))),
      ]),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _secLabel(BuildContext context, String text) {
    final colors = context.colors;
    return Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: colors.textSecondary, letterSpacing: 0.8));
  }
}

// Update Location Tab to accept location data
class _LocationTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  final Map<String, dynamic>? locationData;
  
  const _LocationTab({
    required this.patient, 
    required this.isLandscape,
    this.locationData,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final address = locationData?['address_label'] ?? 'Misr International University';
    final latitude = locationData?['latitude'];
    final longitude = locationData?['longitude'];
    
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: SliverToBoxAdapter(
            child: isLandscape
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _mapCard(context, latitude, longitude)),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: Column(children: [
                      _lastSeenCard(context, address),
                      const SizedBox(height: 14),
                      _journeyCard(context),
                    ])),
                  ])
                : Column(children: [
                    _mapCard(context, latitude, longitude),
                    const SizedBox(height: 14),
                    _lastSeenCard(context, address),
                    const SizedBox(height: 14),
                    _journeyCard(context),
                  ]),
          ),
        ),
      ],
    );
  }

  Widget _mapCard(BuildContext context, double? lat, double? lng) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () {
        if (lat != null && lng != null) {
          // TODO: Open in actual maps app
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Opening in Maps...', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: colors.accent, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ));
        }
      },
      child: Container(
        height: isLandscape ? 260 : 280,
        decoration: BoxDecoration(
          color: colors.background, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          CustomPaint(painter: _MapPainter(), size: Size.infinite),
          const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_pin, color: Color(0xFFE76F51), size: 48),
          ])),
          Positioned(
            top: 14, left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.surface, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text('Active ${patient.lastSeenTime}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ]),
            ),
          ),
          Positioned(
            bottom: 14, right: 14,
            child: GestureDetector(
              onTap: () {
                if (lat != null && lng != null) {
                  // TODO: Launch maps app
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Opening in Maps...', style: TextStyle(fontWeight: FontWeight.w600)),
                    backgroundColor: colors.accent, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accent, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Open in Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _lastSeenCard(BuildContext context, String address) {
    final colors = context.colors;
    return _card(context, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel(context, 'Last Known Location'),
      const SizedBox(height: 12),
      Text(address,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text('Cairo, Egypt', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.access_time_rounded, size: 14, color: colors.textSecondary),
        const SizedBox(width: 5),
        Text('Last seen ${patient.lastSeenTime}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    ]));
  }

  Widget _journeyCard(BuildContext context) {
    final colors = context.colors;
    final stops = [
      ('Home', '7:30 AM', Icons.home_rounded),
      ('On the move', '10:15 AM', Icons.directions_walk_rounded),
      ('University', '11:00 AM', Icons.school_rounded),
      ('On the move', '2:30 PM', Icons.directions_walk_rounded),
      (locationData?['address_label']?.split(',').first ?? 'Current Location', 
       patient.lastSeenTime, Icons.location_on_rounded),
    ];
    return _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel(context, "Today's Journey"),
      const SizedBox(height: 14),
      ...stops.asMap().entries.map((e) {
        final isLast = e.key == stops.length - 1;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isLast
                    ? colors.warning.withValues(alpha: 0.1)
                    : colors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(e.value.$3, size: 15,
                  color: isLast ? colors.warning : colors.accent),
            ),
            if (!isLast)
              Container(width: 2, height: 20, color: colors.textSecondary.withValues(alpha: 0.2)),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isLast ? colors.textPrimary : colors.textSecondary)),
              Text(e.value.$2, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ]),
          )),
        ]);
      }),
    ]));
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _secLabel(BuildContext context, String t) {
    final colors = context.colors;
    return Text(t.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: colors.textSecondary, letterSpacing: 0.8));
  }
}

// Update Doctor Plan Tab to accept carePlan and doctorInfo
class _DoctorPlanTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  final Map<String, dynamic>? carePlan;
  final Map<String, dynamic>? doctorInfo;
  
  const _DoctorPlanTab({
    required this.patient, 
    required this.isLandscape,
    this.carePlan,
    this.doctorInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final targetMin = carePlan?['target_glucose_min'] ?? 70;
    final targetMax = carePlan?['target_glucose_max'] ?? 180;
    final insulinType = carePlan?['insulin_type'] ?? 'NovoLog';
    final aidMode = carePlan?['aid_mode_enabled'] ?? true;
    final maxAutoDose = carePlan?['max_auto_dose_units'] ?? 4.0;
    final nextAppointment = carePlan?['next_appointment'];
    final doctorName = doctorInfo?['full_name'] ?? 'Dr. Nouran';
    
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: SliverList(delegate: SliverChildListDelegate([

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.accent, colors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. Nouran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Endocrinologist  ·  Last updated March 15',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Read Only', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            _planCard(context, title: 'Safe Sugar Range', child: Row(children: [
              Expanded(child: _rangeBox(context, 'Lowest safe', '${targetMin.toInt()} mg/dL', 'Below this is too low', colors.accent)),
              const SizedBox(width: 12),
              Expanded(child: _rangeBox(context, 'Highest safe', '${targetMax.toInt()} mg/dL', 'Above this is too high', colors.warning)),
            ])),

            const SizedBox(height: 14),

            _planCard(context, title: 'Insulin Being Used', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$insulinType ${insulinType == 'NovoLog' ? '(fast-acting)' : ''}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text('This insulin works quickly. The device gives it automatically when needed.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
            ])),

            const SizedBox(height: 14),

            _planCard(context, title: 'How the Device Works', child: Column(children: [
              _planRow(context, 'Mode', aidMode ? 'Fully automatic — no manual doses needed' : 'Manual mode active'),
              _planRow(context, 'Max dose', 'Up to ${maxAutoDose.toInt()} units at a time'),
              _planRow(context, 'Low sugar', 'Pauses insulin if sugar drops below ${targetMin.toInt()}'),
              _planRow(context, 'High sugar', 'Gives extra insulin if sugar goes above ${targetMax.toInt()}'),
            ])),

            const SizedBox(height: 14),

            _planCard(context, title: 'Next Doctor Visit', child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.calendar_today_rounded, color: colors.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nextAppointment != null 
                    ? _formatDate(nextAppointment.toString())
                    : 'Not scheduled',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                if (nextAppointment != null)
                  Text(_daysUntil(nextAppointment.toString()), 
                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ]),
            ])),

            const SizedBox(height: 14),

            _planCard(context, title: "Doctor's Notes for You", child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              _note(context, 'Make sure ${patient.name} eats regular meals — skipping meals can cause low sugar.'),
              _note(context, 'Physical activity lowers blood sugar. Keep snacks nearby when they exercise.'),
              _note(context, 'Sleep is important. Irregular sleep can affect sugar levels.'),
              _note(context, 'If ${patient.name} feels dizzy, shaky, or confused — check the app immediately and give them something sweet.'),
            ])),
          ])),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${_monthAbbr(date.month)} ${date.day}, ${date.year}';
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _daysUntil(String dateStr) {
    final appointmentDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final days = appointmentDate.difference(now).inDays;
    return days == 0 ? 'Today!' : '$days days from now';
  }

  Widget _planCard(BuildContext context, {required String title, required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: colors.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _rangeBox(BuildContext context, String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _planRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textSecondary))),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: colors.textPrimary, height: 1.3))),
      ]),
    );
  }

  Widget _note(BuildContext context, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(top: 5), width: 6, height: 6,
          decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5))),
      ]),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F5F3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final grid = Paint()..color = const Color(0xFFCCE8E3).withValues(alpha: 0.6)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 9;
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.45), road);
    canvas.drawLine(Offset(size.width * 0.45, 0), Offset(size.width * 0.55, size.height), road);

    final block = Paint()..color = const Color(0xFFB2D8D2).withValues(alpha: 0.4)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height * 0.08, size.width * 0.3, size.height * 0.3), const Radius.circular(4)), block);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.62, size.height * 0.1, size.width * 0.28, size.height * 0.25), const Radius.circular(4)), block);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height * 0.64, size.width * 0.25, size.height * 0.26), const Radius.circular(4)), block);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.62, size.height * 0.64, size.width * 0.3, size.height * 0.28), const Radius.circular(4)), block);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}