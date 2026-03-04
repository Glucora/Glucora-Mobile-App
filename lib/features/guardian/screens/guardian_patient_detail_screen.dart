import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GuardianPatientDetailScreen extends StatefulWidget {
  final String patientName;
  final int initialTab;

  const GuardianPatientDetailScreen({
    super.key,
    required this.patientName,
    this.initialTab = 0,
  });

  @override
  State<GuardianPatientDetailScreen> createState() => _GuardianPatientDetailScreenState();
}

class _GuardianPatientDetailScreenState extends State<GuardianPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _callPatient() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Calling ${widget.patientName}...', style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF2A9D8F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _smsPatient() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening SMS for ${widget.patientName}...', style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE76F51),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: OrientationBuilder(builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return Column(children: [
            _buildHeader(isLandscape),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(),
                children: [
                  _OverviewTab(patientName: widget.patientName, isLandscape: isLandscape),
                  _LocationTab(patientName: widget.patientName, isLandscape: isLandscape),
                  _DoctorPlanTab(isLandscape: isLandscape),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildHeader(bool isLandscape) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(8, isLandscape ? 8 : 14, 16, isLandscape ? 8 : 14),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1A2B3C),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: isLandscape ? 18 : 22,
          backgroundColor: const Color(0xFFE76F51).withValues(alpha: 0.15),
          child: Text(
            widget.patientName.substring(0, 1),
            style: TextStyle(
              color: const Color(0xFFE76F51),
              fontWeight: FontWeight.w800,
              fontSize: isLandscape ? 14 : 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.patientName,
                style: TextStyle(fontSize: isLandscape ? 16 : 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A2B3C))),
            const Text('Type 1 Diabetes · Age 24',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        // Quick call & sms in header
        GestureDetector(
          onTap: _smsPatient,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE76F51).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sms_rounded, color: Color(0xFFE76F51), size: 20),
          ),
        ),
        GestureDetector(
          onTap: _callPatient,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.call_rounded, color: Color(0xFF2A9D8F), size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFE76F51),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFE76F51),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Location'),
          Tab(text: 'Doctor Plan'),
        ],
      ),
    );
  }
}

//  OVERVIEW TAB 

class _OverviewTab extends StatelessWidget {
  final String patientName;
  final bool isLandscape;

  const _OverviewTab({required this.patientName, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 12 : 24),
          sliver: isLandscape
              ? SliverToBoxAdapter(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(children: [
                      _glucoseDetailCard(),
                      const SizedBox(height: 14),
                      _deviceCard(),
                    ])),
                    const SizedBox(width: 14),
                    Expanded(child: Column(children: [
                      _insulinDetailCard(),
                      const SizedBox(height: 14),
                      _todayStoryCard(patientName),
                    ])),
                  ]),
                )
              : SliverList(delegate: SliverChildListDelegate([
                  _glucoseDetailCard(),
                  const SizedBox(height: 14),
                  _deviceCard(),
                  const SizedBox(height: 14),
                  _insulinDetailCard(),
                  const SizedBox(height: 14),
                  _todayStoryCard(patientName),
                ])),
        ),
      ],
    );
  }

  Widget _glucoseDetailCard() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Blood Sugar Right Now'),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text('118', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF2A9D8F), letterSpacing: -2, height: 1)),
        const SizedBox(width: 6),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('mg/dL', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: const Row(children: [
            Icon(Icons.trending_flat_rounded, color: Color(0xFF2A9D8F), size: 16),
            SizedBox(width: 5),
            Text('In Range · Steady', style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      // Simple range indicator bar
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Too Low', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          Text('Normal Range', style: TextStyle(fontSize: 10, color: const Color(0xFF2A9D8F), fontWeight: FontWeight.w600)),
          Text('Too High', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(children: [
              Expanded(flex: 2, child: Container(color: const Color(0xFFE63946).withValues(alpha: 0.3))),
              Expanded(flex: 5, child: Container(color: const Color(0xFF2A9D8F).withValues(alpha: 0.25))),
              Expanded(flex: 3, child: Container(color: const Color(0xFFE76F51).withValues(alpha: 0.3))),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        // Pointer
        LayoutBuilder(builder: (ctx, constraints) {
          const double minV = 40, maxV = 300;
          const double val = 118;
          final double pct = ((val - minV) / (maxV - minV)).clamp(0.0, 1.0);
          return Stack(children: [
            const SizedBox(height: 14, width: double.infinity),
            Positioned(
              left: constraints.maxWidth * pct - 6,
              child: const Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF2A9D8F), size: 20),
            ),
          ]);
        }),
      ]),
    ]));
  }

  Widget _deviceCard() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Devices'),
      const SizedBox(height: 10),
      _deviceRow(Icons.sensors, 'Sugar Sensor', 'Connected ', true),
      const SizedBox(height: 8),
      _deviceRow(Icons.water_drop_outlined, 'Insulin Pump', 'Working ', true),
    ]));
  }

  Widget _deviceRow(IconData icon, String label, String status, bool ok) {
    final color = ok ? const Color(0xFF2A9D8F) : const Color(0xFFE63946);
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C))),
      const Spacer(),
      Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

 

  Widget _insulinDetailCard() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Insulin Today'),
      const SizedBox(height: 12),
      Row(children: [
        _insulinStat('4', 'Doses\ngiven'),
        _divider(),
        _insulinStat('All auto', 'How it\nwas given'),
        _divider(),
        _insulinStat('18.3 U', 'Total\namount'),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2A9D8F), size: 16),
          SizedBox(width: 8),
          Flexible(child: Text('The device handled everything automatically today. No manual doses needed.', style: TextStyle(fontSize: 12, color: Color(0xFF2A9D8F), height: 1.4, fontWeight: FontWeight.w500))),
        ]),
      ),
    ]));
  }

  Widget _insulinStat(String value, String label) {
    return Expanded(child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3)),
    ]));
  }

  Widget _divider() => Container(height: 36, width: 1, color: Colors.grey.shade100);

  Widget _todayStoryCard(String name) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Today in a nutshell'),
      const SizedBox(height: 12),
      _storyItem('Morning', 'Sugar was good when $name woke up', true),
      _storyItem('Breakfast', 'Ate breakfast, device gave insulin automatically', true),
      _storyItem('Midday', 'Sugar stayed in the safe zone', true),
      _storyItem('Lunch', 'Had lunch, all normal', true),
      _storyItem('Now', 'Doing well — sugar is in the normal range', true),
    ]));
  }

  Widget _storyItem(String time, String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: ok ? const Color(0xFF2A9D8F) : const Color(0xFFE76F51),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: RichText(text: TextSpan(children: [
          TextSpan(text: '$time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
          TextSpan(text: text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
        ]))),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.8),
  );
}

//  LOCATION TAB 

class _LocationTab extends StatelessWidget {
  final String patientName;
  final bool isLandscape;

  const _LocationTab({required this.patientName, required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 10 : 20),
            child: isLandscape
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _mapCard(context)),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: Column(children: [
                      _lastSeenCard(),
                      const SizedBox(height: 14),
                      _locationHistoryCard(),
                    ])),
                  ])
                : Column(children: [
                    _mapCard(context),
                    const SizedBox(height: 14),
                    _lastSeenCard(),
                    const SizedBox(height: 14),
                    _locationHistoryCard(),
                  ]),
          ),
        ),
      ],
    );
  }

  Widget _mapCard(BuildContext context) {
    return Container(
      height: isLandscape ? 260 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // Map placeholder — replace with google_maps_flutter widget
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8F5F3), Color(0xFFD4EEE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(painter: _MapPlaceholderPainter(), size: Size.infinite),
        ),
        // Patient pin
        const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_pin, color: Color(0xFFE76F51), size: 48),
            SizedBox(height: 2),
          ]),
        ),
        // "Last seen" chip overlay
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('Active 5 min ago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2B3C))),
            ]),
          ),
        ),
        // Open maps button
        Positioned(
          bottom: 14,
          right: 14,
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Opening in Maps...', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF5B8CF5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8CF5),
                borderRadius: BorderRadius.circular(20),
              ),
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
  }

  Widget _lastSeenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('Last Known Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 12),
        const Text('Cairo University Area', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
        const SizedBox(height: 4),
        Text('Giza, Egypt', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 5),
          Text('Last seen 5 minutes ago', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _locationHistoryCard() {
    final history = [
      ('Home', '7:30 AM', Icons.home_rounded),
      ('On the move', '10:15 AM', Icons.directions_walk_rounded),
      ('University', '11:00 AM', Icons.school_rounded),
      ('On the move', '2:30 PM', Icons.directions_walk_rounded),
      ('Cairo University Area', '3:10 PM', Icons.location_on_rounded),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('Today\'s Journey', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 14),
        ...history.asMap().entries.map((e) {
          final isLast = e.key == history.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isLast
                      ? const Color(0xFFE76F51).withValues(alpha: 0.12)
                      : const Color(0xFF2A9D8F).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(e.value.$3, size: 15, color: isLast ? const Color(0xFFE76F51) : const Color(0xFF2A9D8F)),
              ),
              if (!isLast)
                Container(width: 2, height: 20, color: Colors.grey.shade100),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isLast ? const Color(0xFF1A2B3C) : Colors.grey.shade600)),
                  Text(e.value.$2, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ]),
              ),
            ),
          ]);
        }),
      ]),
    );
  }
}

//  MAP PLACEHOLDER PAINTER 

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCCE8E3).withValues(alpha: 0.5)..strokeWidth = 1;

    // Simple grid lines to suggest a map
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint..style = PaintingStyle.stroke);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint..style = PaintingStyle.stroke);
    }

    // Road-like stripes
    final roadPaint = Paint()..color = Colors.white.withValues(alpha: 0.7)..strokeWidth = 8;
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.45, 0), Offset(size.width * 0.55, size.height), roadPaint);

    // Block fills
    final blockPaint = Paint()..color = const Color(0xFFB2D8D2).withValues(alpha: 0.3)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.3, size.height * 0.3), blockPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, size.height * 0.15, size.width * 0.25, size.height * 0.2), blockPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.62, size.width * 0.2, size.height * 0.25), blockPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, size.height * 0.62, size.width * 0.3, size.height * 0.28), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//  DOCTOR PLAN TAB 

class _DoctorPlanTab extends StatelessWidget {
  final bool isLandscape;
  const _DoctorPlanTab({required this.isLandscape});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, isLandscape ? 10 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Doctor info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A9D8F), Color(0xFF1A7A6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                    Text('Endocrinologist · Last updated March 15', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Read Only', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Safe sugar range — super simplified
              _planCard(
                title: 'Safe Sugar Range',
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _rangeBox('Lowest safe', '70 mg/dL', 'Below this is too low', const Color(0xFF5B8CF5))),
                    const SizedBox(width: 12),
                    Expanded(child: _rangeBox('Highest safe', '180 mg/dL', 'Above this is too high', const Color(0xFFE76F51))),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF2A9D8F), size: 16),
                      SizedBox(width: 8),
                      Flexible(child: Text('The device automatically keeps Ahmed\'s sugar in this safe range.', style: TextStyle(fontSize: 12, color: Color(0xFF2A9D8F), height: 1.4, fontWeight: FontWeight.w500))),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 14),

              // Insulin info — simplified
              _planCard(
                title: 'Insulin Ahmed Uses',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('NovoLog (fast-acting)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
                  const SizedBox(height: 6),
                  Text('This is a type of insulin that works quickly. The device gives it automatically when needed.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                ]),
              ),

              const SizedBox(height: 14),

              // AID mode — simplified
              _planCard(
                title: 'How the Device Works',
                child: Column(children: [
                  _planRow('Mode', 'Fully automatic — no manual doses needed'),
                  _planRow('Auto doses', 'Up to 4 units at a time'),
                  _planRow('Low protection', 'Pauses insulin if sugar drops below 70'),
                  _planRow('High correction', 'Gives extra insulin if sugar goes above 180'),
                ]),
              ),

              const SizedBox(height: 14),

              // Next appointment
              _planCard(
                title: 'Next Doctor Visit',
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF5B8CF5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF5B8CF5), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('April 2, 2025', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
                    SizedBox(height: 2),
                    Text('18 days from now', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ]),
              ),

              const SizedBox(height: 14),

              // Doctor notes — simplified
              _planCard(
                title: 'Doctor\'s Notes for Guardians',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _notePoint('Make sure Ahmed eats regular meals — skipping meals can cause low sugar.'),
                  _notePoint('Physical activity lowers blood sugar. Keep snacks nearby when he exercises.'),
                  _notePoint('Sleep is important. Irregular sleep can affect sugar levels.'),
                  _notePoint('If Ahmed feels dizzy, shaky, or confused — check his app immediately and give him something sweet to eat.'),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _planCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.8)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _rangeBox(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _planRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2B3C), height: 1.3))),
      ]),
    );
  }

  Widget _notePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(top: 5), width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF2A9D8F), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5))),
      ]),
    );
  }
}