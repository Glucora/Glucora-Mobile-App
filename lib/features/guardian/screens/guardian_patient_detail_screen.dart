import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guardian_patient_model.dart';
import 'guardian_home_screen.dart' show GuardianHomeScreen;

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

  static Color statusColor(String s) {
    switch (s) {
      case 'emergency': return const Color(0xFFE63946);
      case 'attention': return const Color(0xFFE76F51);
      default:          return const Color(0xFF2A9D8F);
    }
  }

  static Color glucoseColor(GuardianPatient p) {
    switch (p.glucoseLabel) {
      case 'Too high': case 'Very high': case 'Too low': case 'Very low':
        return const Color(0xFFE63946);
      case 'A bit high': return const Color(0xFFE76F51);
      default:           return const Color(0xFF2A9D8F);
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _call() {
    HapticFeedback.mediumImpact();
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
  Widget build(BuildContext context) {
    final p = widget.patient;
    final sColor = statusColor(p.overallStatus);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OrientationBuilder(builder: (ctx, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return Column(children: [

            // ── Header ────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(8, isLandscape ? 8 : 14, 16, isLandscape ? 8 : 14),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: const Color(0xFF1A2B3C),
                ),
                CircleAvatar(
                  radius: isLandscape ? 18 : 22,
                  backgroundColor: sColor.withValues(alpha: 0.12),
                  child: Text(p.name.substring(0, 1),
                      style: TextStyle(color: sColor, fontWeight: FontWeight.w800,
                          fontSize: isLandscape ? 14 : 16)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: TextStyle(
                      fontSize: isLandscape ? 15 : 18,
                      fontWeight: FontWeight.w800, color: const Color(0xFF1A2B3C))),
                  Text('${p.relationship}  ·  Age ${p.age}  ·  Type 1',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ])),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.overallStatus == 'emergency' ? 'Needs help now'
                        : p.overallStatus == 'attention' ? 'Needs attention' : 'Doing well',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sColor),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sms,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE76F51).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sms_rounded, color: Color(0xFFE76F51), size: 19),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _call,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.call_rounded, color: Color(0xFF2A9D8F), size: 19),
                  ),
                ),
              ]),
            ),

            // ── Tabs ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: TabBar(
                controller: _tab,
                labelColor: const Color(0xFF2A9D8F),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2A9D8F),
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
                  _OverviewTab(patient: p, isLandscape: isLandscape),
                  _LocationTab(patient: p, isLandscape: isLandscape),
                  _DoctorPlanTab(patient: p, isLandscape: isLandscape),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

// ─── OVERVIEW TAB ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _OverviewTab({required this.patient, required this.isLandscape});

  Color get gColor => _GuardianPatientDetailScreenState.glucoseColor(patient);

  IconData get tIcon {
    switch (patient.glucoseTrend) {
      case 'up':   return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default:     return Icons.trending_flat_rounded;
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
              ? SliverToBoxAdapter(child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: [
                      _glucoseCard(),
                      const SizedBox(height: 14),
                      _devicesCard(),
                    ])),
                    const SizedBox(width: 14),
                    Expanded(child: Column(children: [
                      _insulinCard(),
                      const SizedBox(height: 14),
                      _todayCard(),
                    ])),
                  ],
                ))
              : SliverList(delegate: SliverChildListDelegate([
                  _glucoseCard(),
                  const SizedBox(height: 14),
                  _devicesCard(),
                  const SizedBox(height: 14),
                  _insulinCard(),
                  const SizedBox(height: 14),
                  _todayCard(),
                ])),
        ),
      ],
    );
  }

  Widget _glucoseCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Blood Sugar Right Now'),
    const SizedBox(height: 12),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('${patient.glucoseValue}',
          style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900,
              color: gColor, letterSpacing: -2, height: 1)),
      const SizedBox(width: 6),
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text('mg/dL', style: TextStyle(fontSize: 13,
              color: Colors.grey.shade400, fontWeight: FontWeight.w500))),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: gColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(tIcon, color: gColor, size: 14),
          const SizedBox(width: 5),
          Text(patient.glucoseLabel,
              style: TextStyle(color: gColor, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    ]),
    const SizedBox(height: 12),
    // Range bar
    _rangeBar(),
  ]));

  Widget _rangeBar() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Too Low', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      Text('Normal Range', style: TextStyle(fontSize: 10, color: const Color(0xFF2A9D8F), fontWeight: FontWeight.w600)),
      Text('Too High', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(height: 10, child: Row(children: [
        Expanded(flex: 2, child: Container(color: const Color(0xFFE63946).withValues(alpha: 0.3))),
        Expanded(flex: 5, child: Container(color: const Color(0xFF2A9D8F).withValues(alpha: 0.25))),
        Expanded(flex: 3, child: Container(color: const Color(0xFFE76F51).withValues(alpha: 0.3))),
      ])),
    ),
    const SizedBox(height: 4),
    LayoutBuilder(builder: (ctx, constraints) {
      const double minV = 40, maxV = 300;
      final double pct = ((patient.glucoseValue - minV) / (maxV - minV)).clamp(0.0, 1.0);
      return Stack(children: [
        const SizedBox(height: 14, width: double.infinity),
        Positioned(
          left: (constraints.maxWidth * pct - 6).clamp(0.0, constraints.maxWidth - 12),
          child: Icon(Icons.arrow_drop_up_rounded, color: gColor, size: 20),
        ),
      ]);
    }),
  ]);

  Widget _devicesCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Devices'),
    const SizedBox(height: 12),
    _deviceRow(Icons.sensors, 'Sugar Sensor',
        patient.sensorConnected ? 'Connected' : 'Disconnected', patient.sensorConnected),
    const SizedBox(height: 8),
    _deviceRow(Icons.water_drop_outlined, 'Insulin Pump',
        patient.pumpActive ? 'Working' : 'Paused', patient.pumpActive),
  ]));

  Widget _deviceRow(IconData icon, String label, String status, bool ok) {
    final color = ok ? const Color(0xFF2A9D8F) : const Color(0xFFE63946);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }

  Widget _insulinCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Insulin Today'),
    const SizedBox(height: 12),
    Row(children: [
      _stat('${patient.dosesToday}', 'Doses given'),
      _divider(),
      _stat(patient.allDosesAutomatic ? 'Auto' : 'Manual', 'How given'),
      _divider(),
      _stat('18.3 U', 'Total amount'),
    ]),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A9D8F).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2A9D8F), size: 16),
        const SizedBox(width: 8),
        Flexible(child: Text(
          patient.allDosesAutomatic
              ? 'The device handled everything automatically today.'
              : 'Some doses were given manually today.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF2A9D8F), height: 1.4, fontWeight: FontWeight.w500),
        )),
      ]),
    ),
  ]));

  Widget _stat(String val, String label) => Expanded(child: Column(children: [
    Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
    const SizedBox(height: 2),
    Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3)),
  ]));

  Widget _divider() =>
      Container(height: 36, width: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _todayCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Today at a Glance'),
    const SizedBox(height: 12),
    _story('Morning',  'Sugar was in the safe zone when ${patient.name} woke up', true),
    _story('Breakfast', 'Ate breakfast, device gave insulin automatically', true),
    _story('Midday',   'Sugar stayed in the normal range', true),
    _story('Now',      patient.glucoseLabel == 'In Range'
        ? 'Doing well — sugar is in the normal range'
        : 'Sugar is ${patient.glucoseLabel.toLowerCase()} — device is managing it',
        patient.glucoseLabel == 'In Range'),
  ]));

  Widget _story(String time, String text, bool ok) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(top: 4),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: ok ? const Color(0xFF2A9D8F) : const Color(0xFFE76F51),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: RichText(text: TextSpan(children: [
        TextSpan(text: '$time  ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
        TextSpan(text: text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
      ]))),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _secLabel(String text) => Text(text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.grey.shade400, letterSpacing: 0.8));
}

// ─── LOCATION TAB ────────────────────────────────────────────────────────────

class _LocationTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _LocationTab({required this.patient, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: SliverToBoxAdapter(
            child: isLandscape
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _mapCard(context)),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: Column(children: [
                      _lastSeenCard(),
                      const SizedBox(height: 14),
                      _journeyCard(),
                    ])),
                  ])
                : Column(children: [
                    _mapCard(context),
                    const SizedBox(height: 14),
                    _lastSeenCard(),
                    const SizedBox(height: 14),
                    _journeyCard(),
                  ]),
          ),
        ),
      ],
    );
  }

  Widget _mapCard(BuildContext context) => Container(
    height: isLandscape ? 260 : 280,
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FA), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      CustomPaint(painter: _MapPainter(), size: Size.infinite),
      // Location pin
      const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_pin, color: Color(0xFFE76F51), size: 48),
      ])),
      // Active chip
      Positioned(
        top: 14, left: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text('Active ${patient.lastSeenTime}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
          ]),
        ),
      ),
      // Open in maps
      Positioned(
        bottom: 14, right: 14,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Opening in Maps...', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF2A9D8F), behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A9D8F), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
              SizedBox(width: 6),
              Text('Open in Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
        ),
      ),
    ]),
  );

  Widget _lastSeenCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _secLabel('Last Known Location'),
    const SizedBox(height: 12),
    const Text('Misr International University',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
    const SizedBox(height: 3),
    Text('Cairo, Egypt', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    const SizedBox(height: 10),
    Row(children: [
      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
      const SizedBox(width: 5),
      Text('Last seen ${patient.lastSeenTime}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
    ]),
  ]));

  Widget _journeyCard() {
    final stops = [
      ('Home', '7:30 AM', Icons.home_rounded),
      ('On the move', '10:15 AM', Icons.directions_walk_rounded),
      ('University', '11:00 AM', Icons.school_rounded),
      ('On the move', '2:30 PM', Icons.directions_walk_rounded),
      ('Misr International University', '3:10 PM', Icons.location_on_rounded),
    ];
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secLabel("Today's Journey"),
      const SizedBox(height: 14),
      ...stops.asMap().entries.map((e) {
        final isLast = e.key == stops.length - 1;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isLast
                    ? const Color(0xFFE76F51).withValues(alpha: 0.1)
                    : const Color(0xFF2A9D8F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(e.value.$3, size: 15,
                  color: isLast ? const Color(0xFFE76F51) : const Color(0xFF2A9D8F)),
            ),
            if (!isLast)
              Container(width: 2, height: 20, color: Colors.grey.shade100),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isLast ? const Color(0xFF1A2B3C) : Colors.grey.shade500)),
              Text(e.value.$2, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
          )),
        ]);
      }),
    ]));
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _secLabel(String t) => Text(t.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.grey.shade400, letterSpacing: 0.8));
}

// ─── DOCTOR PLAN TAB ─────────────────────────────────────────────────────────

class _DoctorPlanTab extends StatelessWidget {
  final GuardianPatient patient;
  final bool isLandscape;
  const _DoctorPlanTab({required this.patient, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // Doctor banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A9D8F), Color(0xFF1A7A6E)],
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

            // Safe range
            _planCard(title: 'Safe Sugar Range', child: Row(children: [
              Expanded(child: _rangeBox('Lowest safe', '70 mg/dL', 'Below this is too low', const Color(0xFF2A9D8F))),
              const SizedBox(width: 12),
              Expanded(child: _rangeBox('Highest safe', '180 mg/dL', 'Above this is too high', const Color(0xFFE76F51))),
            ])),

            const SizedBox(height: 14),

            // Insulin type
            _planCard(title: 'Insulin Being Used', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NovoLog (fast-acting)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
              const SizedBox(height: 6),
              Text('This insulin works quickly. The device gives it automatically when needed.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            ])),

            const SizedBox(height: 14),

            // How device works
            _planCard(title: 'How the Device Works', child: Column(children: [
              _planRow('Mode', 'Fully automatic — no manual doses needed'),
              _planRow('Max dose', 'Up to 4 units at a time'),
              _planRow('Low sugar', 'Pauses insulin if sugar drops below 70'),
              _planRow('High sugar', 'Gives extra insulin if sugar goes above 180'),
            ])),

            const SizedBox(height: 14),

            // Next appointment
            _planCard(title: 'Next Doctor Visit', child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2A9D8F), size: 24),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('April 2, 2025',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
                SizedBox(height: 2),
                Text('18 days from now', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ])),

            const SizedBox(height: 14),

            // Notes for guardian
            _planCard(title: "Doctor's Notes for You", child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              _note('Make sure ${patient.name} eats regular meals — skipping meals can cause low sugar.'),
              _note('Physical activity lowers blood sugar. Keep snacks nearby when they exercise.'),
              _note('Sleep is important. Irregular sleep can affect sugar levels.'),
              _note('If ${patient.name} feels dizzy, shaky, or confused — check the app immediately and give them something sweet.'),
            ])),
          ])),
        ),
      ],
    );
  }

  Widget _planCard({required String title, required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: Colors.grey.shade400, letterSpacing: 0.8)),
      const SizedBox(height: 14),
      child,
    ]),
  );

  Widget _rangeBox(String label, String value, String sub, Color color) => Container(
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

  Widget _planRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF1A2B3C), height: 1.3))),
    ]),
  );

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(top: 5), width: 6, height: 6,
        decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5))),
    ]),
  );
}

// ─── MAP PLACEHOLDER PAINTER ─────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F5F3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final grid = Paint()..color = const Color(0xFFCCE8E3).withValues(alpha: 0.6)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += 36)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);

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

// expose for use in detail screen
