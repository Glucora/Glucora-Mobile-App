import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guardian_patient_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
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
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
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
                        child: Text(
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
                            Text(
                              p.name,
                              style: TextStyle(
                                fontSize: isLandscape ? 15 : 18,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
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
                        child: Text(
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
                      _LocationTab(patient: p, isLandscape: isLandscape),
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

class _OverviewTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _OverviewTab({required this.patient, required this.isLandscape});

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
    final colors = context.colors;
    final glucoseColorVal = gColor(context);

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
              Text(
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
                child: Text(
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
                    Text(
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
            Text(
              'Too Low',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
            Text(
              'Normal Range',
              style: TextStyle(
                fontSize: 10,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
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
    final colors = context.colors;
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
        Text(
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
          child: Text(
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
              _stat(colors, '18.3 U', 'Total amount'),
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
                  child: Text(
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
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
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
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel(context, 'Today at a Glance'),
          const SizedBox(height: 12),
          _story(
            context,
            'Morning',
            'Sugar was in the safe zone when ${patient.name} woke up',
            true,
          ),
          _story(
            context,
            'Breakfast',
            'Ate breakfast, device gave insulin automatically',
            true,
          ),
          _story(context, 'Midday', 'Sugar stayed in the normal range', true),
          _story(
            context,
            'Now',
            patient.glucoseLabel == 'In Range'
                ? 'Doing well — sugar is in the normal range'
                : 'Sugar is ${patient.glucoseLabel.toLowerCase()} — device is managing it',
            patient.glucoseLabel == 'In Range',
          ),
        ],
      ),
    );
  }

  Widget _story(BuildContext context, String time, String text, bool ok) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ok ? colors.accent : colors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$time  ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Text(
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

// ─── LOCATION TAB ────────────────────────────────────────────────────────────
class _LocationTab extends StatefulWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _LocationTab({required this.patient, required this.isLandscape});

  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  double? _lat;
  double? _lng;
  String _lastSeen = 'Loading...';
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchAndListen();
  }

  Future<void> _fetchAndListen() async {
    // First fetch current location
    try {
      final data = await Supabase.instance.client
          .from('patient_locations')
          .select()
          .eq('patient_id', widget.patient.patientId)
          .single();

      if (mounted) {
        setState(() {
          _lat = (data['latitude'] as num).toDouble();
          _lng = (data['longitude'] as num).toDouble();
          _lastSeen = _timeAgo(data['updated_at']);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }

    // Then listen for real time updates
    _channel = Supabase.instance.client
        .channel('location_${widget.patient.patientId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'patient_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: widget.patient.patientId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final row = payload.newRecord;
            setState(() {
              _lat = (row['latitude'] as num).toDouble();
              _lng = (row['longitude'] as num).toDouble();
              _lastSeen = _timeAgo(row['updated_at']);
            });
          },
        )
        .subscribe();
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return 'Unknown';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _openInMaps() async {
    if (_lat == null || _lng == null) return;
    final uri = Uri.parse('geo:$_lat,$_lng?q=$_lat,$_lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }

    if (_lat == null || _lng == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 48,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Location not available',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Patient may have location sharing off',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: SliverToBoxAdapter(
            child: widget.isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _mapCard(context)),
                      const SizedBox(width: 14),
                      Expanded(flex: 2, child: _lastSeenCard(context)),
                    ],
                  )
                : Column(
                    children: [
                      _mapCard(context),
                      const SizedBox(height: 14),
                      _lastSeenCard(context),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  bool get isLandscape => widget.isLandscape;

  Widget _mapCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: isLandscape ? 260 : 320,
      decoration: BoxDecoration(
        color: colors.background,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_lat!, _lng!),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.glucora.companion',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_lat!, _lng!),
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFE76F51),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Updated $_lastSeen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lastSeenCard(BuildContext context) {
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
          Text(
            'LIVE LOCATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.my_location_rounded, color: colors.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                'Last updated $_lastSeen',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text(
                'Get Directions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DOCTOR PLAN TAB ─────────────────────────────────────────────────────────

class _DoctorPlanTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _DoctorPlanTab({required this.patient, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Nouran',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Endocrinologist  ·  Last updated March 15',
                            style: TextStyle(
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
                      child: const Text(
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

              _planCard(
                context,
                title: 'Safe Sugar Range',
                child: Row(
                  children: [
                    Expanded(
                      child: _rangeBox(
                        context,
                        'Lowest safe',
                        '70 mg/dL',
                        'Below this is too low',
                        colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _rangeBox(
                        context,
                        'Highest safe',
                        '180 mg/dL',
                        'Above this is too high',
                        colors.warning,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _planCard(
                context,
                title: 'Insulin Being Used',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NovoLog (fast-acting)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
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

              _planCard(
                context,
                title: 'How the Device Works',
                child: Column(
                  children: [
                    _planRow(
                      context,
                      'Mode',
                      'Fully automatic — no manual doses needed',
                    ),
                    _planRow(context, 'Max dose', 'Up to 4 units at a time'),
                    _planRow(
                      context,
                      'Low sugar',
                      'Pauses insulin if sugar drops below 70',
                    ),
                    _planRow(
                      context,
                      'High sugar',
                      'Gives extra insulin if sugar goes above 180',
                    ),
                  ],
                ),
              ),

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
                        Text(
                          'April 2, 2025',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '18 days from now',
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

              const SizedBox(height: 14),

              _planCard(
                context,
                title: "Doctor's Notes for You",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _note(
                      context,
                      'Make sure ${patient.name} eats regular meals — skipping meals can cause low sugar.',
                    ),
                    _note(
                      context,
                      'Physical activity lowers blood sugar. Keep snacks nearby when they exercise.',
                    ),
                    _note(
                      context,
                      'Sleep is important. Irregular sleep can affect sugar levels.',
                    ),
                    _note(
                      context,
                      'If ${patient.name} feels dizzy, shaky, or confused — check the app immediately and give them something sweet.',
                    ),
                  ],
                ),
              ),
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
          Text(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
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
            child: Text(
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
