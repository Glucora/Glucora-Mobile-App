import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guardian_patient_model.dart';
import 'guardian_patient_detail_screen.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});
  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterStatus;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<GuardianPatient> get _filtered =>
      GuardianMockData.patients.where((p) {
        final q = _query.toLowerCase();
        final matchQ = q.isEmpty || p.name.toLowerCase().contains(q) ||
            p.relationship.toLowerCase().contains(q);
        final matchF = _filterStatus == null || p.overallStatus == _filterStatus;
        return matchQ && matchF;
      }).toList()
        ..sort((a, b) {
          const o = {'emergency': 0, 'attention': 1, 'good': 2};
          return (o[a.overallStatus] ?? 2).compareTo(o[b.overallStatus] ?? 2);
        });

  int get _emergencyCount => GuardianMockData.patients.where((p) => p.overallStatus == 'emergency').length;
  int get _attentionCount => GuardianMockData.patients.where((p) => p.overallStatus == 'attention').length;

  // ── Calm color system ─────────────────────────────────────────────────────
  // No red anywhere. Amber for urgent, blue for attention, teal for good.
  static Color statusColor(String s) {
    switch (s) {
      case 'emergency': return const Color.fromARGB(255, 192, 0, 0); // deep amber — serious but not scary
      case 'attention': return const Color(0xFFC07A00); // soft blue — informational
      default:          return const Color(0xFF2A9D8F); // teal — calm
    }
  }

  static Color statusBg(String s) {
    switch (s) {
      case 'emergency': return const Color.fromARGB(255, 255, 239, 236);
      case 'attention': return const Color(0xFFFFF4E0);
      default:          return const Color(0xFFE8F5F3);
    }
  }

  // Friendly, non-alarming language
  static String statusLabel(String s) {
    switch (s) {
      case 'emergency': return 'Check on them';
      case 'attention': return 'Worth a look';
      default:          return 'Doing well';
    }
  }

  static Color glucoseColor(GuardianPatient p) {
    switch (p.glucoseLabel) {
      case 'Too high': case 'Very high':
      case 'Too low':  case 'Very low':  return const Color(0xFFE63946);
      case 'A bit high':                 return const Color(0xFFC07A00);
      default:                           return const Color(0xFF2A9D8F);
    }
  }

  static IconData trendIcon(String t) {
    switch (t) {
      case 'up':   return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default:     return Icons.trending_flat_rounded;
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        current: _filterStatus,
        onApply: (v) => setState(() => _filterStatus = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OrientationBuilder(builder: (ctx, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [

              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, isLandscape ? 10 : 24, 20, 0),
                  child: isLandscape
                      ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Expanded(child: _titleBlock()),
                          const SizedBox(width: 16),
                          _statusPills(),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _titleBlock(),
                          const SizedBox(height: 10),
                          _statusPills(),
                        ]),
                ),
              ),

              // ── Soft nudge bar — only when someone needs attention ───────
              if (_emergencyCount > 0 || _attentionCount > 0)
                SliverToBoxAdapter(child: _nudgeBar()),

              // ── Search + filter ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                            hintText: 'Search by name or relationship...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            border: InputBorder.none,
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                                    onPressed: () => setState(() { _query = ''; _searchCtrl.clear(); }),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(clipBehavior: Clip.none, children: [
                      GestureDetector(
                        onTap: _showFilter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: _filterStatus != null
                                ? const Color(0xFF2A9D8F)
                                : const Color(0xFFF4F7FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: _filterStatus != null ? Colors.white : Colors.grey.shade500,
                              size: 20),
                        ),
                      ),
                      if (_filterStatus != null)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 14, height: 14,
                            decoration: const BoxDecoration(
                                color: Color(0xFF2A9D8F), shape: BoxShape.circle),
                            child: const Center(
                              child: Text('1',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                    ]),
                  ]),
                ),
              ),

              // ── Patient count row ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(children: [
                    const Text('Your Patients',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
                    const Spacer(),
                    Text('${list.length} of ${GuardianMockData.patients.length}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ]),
                ),
              ),

              // ── Empty state ──────────────────────────────────────────────
              if (list.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No patients match your search.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                      if (_filterStatus != null || _query.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            _filterStatus = null; _query = ''; _searchCtrl.clear();
                          }),
                          child: const Text('Clear filters',
                              style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),

              // ── Patient cards ────────────────────────────────────────────
              if (list.isNotEmpty)
                isLandscape
                    ? SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 14,
                            mainAxisSpacing: 0, mainAxisExtent: 230,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildCard(list[i]),
                            childCount: list.length,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildCard(list[i]),
                            childCount: list.length,
                          ),
                        ),
                      ),
            ],
          );
        }),
      ),
    );
  }

  // ── Title block ────────────────────────────────────────────────────────────
  Widget _titleBlock() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(greeting,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B3C), letterSpacing: -0.5)),
      const SizedBox(height: 3),
      Text('Watching over ${GuardianMockData.patients.length} people',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w400)),
    ]);
  }

  // ── Status pills — calm palette, no red ───────────────────────────────────
  Widget _statusPills() {
    final good = GuardianMockData.patients.where((p) => p.overallStatus == 'good').length;
    return Wrap(spacing: 8, children: [
      _pill('$good Doing well',       const Color(0xFF2A9D8F), const Color(0xFFE8F5F3)),
      if (_attentionCount > 0)
        _pill('$_attentionCount Worth a look', const Color(0xFFC07A00), const Color(0xFFFFF4E0)),
      if (_emergencyCount > 0)
        _pill('$_emergencyCount Check on them', const Color(0xFFE63946), const Color.fromARGB(255, 255, 224, 224)),
    ]);
  }

  Widget _pill(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  // ── Soft nudge bar — friendly tone, no warning icons ─────────────────────
  Widget _nudgeBar() {
    final urgentNames = GuardianMockData.patients
        .where((p) => p.overallStatus == 'emergency')
        .map((p) => p.name).toList();
    final attnNames = GuardianMockData.patients
        .where((p) => p.overallStatus == 'attention')
        .map((p) => p.name).toList();

    final bool isUrgent = urgentNames.isNotEmpty;
    final names = isUrgent ? urgentNames : attnNames;
    final color = isUrgent ? const Color(0xFFE63946) : const Color(0xFF2A9D8F);
    final bg    = isUrgent ? const Color.fromARGB(255, 255, 236, 236) : const Color(0xFFFFF8EC);

    final message = isUrgent
        ? 'It might be a good time to check on ${names.join(' and ')}'
        : "${names.join(' and ')}'s sugar is slightly off — nothing urgent";

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.favorite_border_rounded, color: color, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: color, height: 1.4)),
        ),
      ]),
    );
  }

  // ── Patient card ───────────────────────────────────────────────────────────
  Widget _buildCard(GuardianPatient p) {
    final sColor = statusColor(p.overallStatus);
    final sBg    = statusBg(p.overallStatus);
    final gColor = glucoseColor(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Only a very subtle tinted border for non-good — never a harsh red outline
        border: Border.all(
          color: p.overallStatus == 'good'
              ? Colors.grey.shade100
              : sColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(children: [

        // ── Identity row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: sBg,
              child: Text(p.name.substring(0, 1),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: sColor)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
              const SizedBox(height: 2),
              Text('${p.relationship}  ·  Age ${p.age}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ])),
            // Calm status badge — soft background, no border
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel(p.overallStatus),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sColor)),
            ),
          ]),
        ),

        // ── Glucose strip ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text('${p.glucoseValue}',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                    color: gColor, letterSpacing: -1)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('mg/dL',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(trendIcon(p.glucoseTrend), color: gColor, size: 13),
                const SizedBox(width: 3),
                Text(p.glucoseLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gColor)),
              ]),
            ),
            const Spacer(),
            // Device status — quiet text, no alarming dots
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _deviceLine(Icons.sensors, 'Sensor', p.sensorConnected),
              const SizedBox(height: 2),
              _deviceLine(Icons.water_drop_outlined, 'Pump', p.pumpActive),
            ]),
          ]),
        ),

        // ── Offline notice — soft, not alarming ──
        if (!p.sensorConnected || !p.pumpActive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              if (!p.sensorConnected)
                _softChip('Sensor is off', const Color(0xFFE63946), const Color.fromARGB(255, 255, 238, 238)),
              if (!p.sensorConnected && !p.pumpActive) const SizedBox(width: 6),
              if (!p.pumpActive)
                _softChip('Pump is paused', const Color(0xFFE63946), const Color.fromARGB(255, 255, 238, 238)),
            ]),
          ),

        // ── Actions ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            _actionBtn(Icons.call_rounded, 'Call', const Color(0xFF2A9D8F),
                () { HapticFeedback.mediumImpact(); _snack('Calling ${p.name}...', const Color(0xFF2A9D8F)); }),
            const SizedBox(width: 8),
            _actionBtn(Icons.sms_rounded, 'SMS', const Color(0xFF5B8CF5),
                () => _snack('Opening SMS for ${p.name}...', const Color(0xFF5B8CF5))),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => GuardianPatientDetailScreen(patient: p),
              )),
              child: Row(children: [
                Text('View details',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400)),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade300),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _deviceLine(IconData icon, String label, bool ok) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11,
        color: ok ? const Color(0xFF2A9D8F) : Colors.grey.shade400),
    const SizedBox(width: 3),
    Text(ok ? '$label on' : '$label off',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
            color: ok ? const Color(0xFF2A9D8F) : Colors.grey.shade400)),
  ]);

  Widget _softChip(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );
}

// ─── FILTER BOTTOM SHEET ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String? current;
  final ValueChanged<String?> onApply;
  const _FilterSheet({required this.current, required this.onApply});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _sel;
  @override
  void initState() { super.initState(); _sel = widget.current; }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Filter by Status',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
          if (_sel != null)
            TextButton(
              onPressed: () { setState(() => _sel = null); widget.onApply(null); Navigator.pop(context); },
              child: const Text('Clear',
                  style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 16),
        _opt(null,        'All Patients',    'Show everyone',                           Colors.grey,             const Color(0xFFF4F7FA)),
        const SizedBox(height: 8),
        _opt('good',      'Doing Well',      'Sugar is in the normal range',            const Color(0xFF2A9D8F),  const Color(0xFFE8F5F3)),
        const SizedBox(height: 8),
        _opt('attention', 'Worth a Look',    'Sugar slightly off — nothing to worry',   const Color(0xFFC07A00),  const Color(0xFFFFF4E0)),
        const SizedBox(height: 8),
        _opt('emergency', 'Check on Them',   'May be a good time to reach out',         const Color(0xFFE63946),  const Color.fromARGB(255, 255, 224, 224)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () { widget.onApply(_sel); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F), foregroundColor: Colors.white,
              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_sel == null ? 'Show All Patients' : 'Apply Filter',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _opt(String? value, String title, String subtitle, Color color, Color bg) {
    final active = _sel == value;
    return GestureDetector(
      onTap: () => setState(() => _sel = (active && value != null) ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? bg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.35) : Colors.grey.shade100,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: active ? color : const Color(0xFF1A2B3C))),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
          if (active) Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}