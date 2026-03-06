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
  String? _filterStatus; // null=all | 'good' | 'attention' | 'emergency'

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

  static Color statusColor(String s) {
    switch (s) {
      case 'emergency': return const Color(0xFFE63946);
      case 'attention': return const Color(0xFFE76F51);
      default:          return const Color(0xFF2A9D8F);
    }
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'emergency': return 'Needs help now';
      case 'attention': return 'Needs attention';
      default:          return 'Doing well';
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

  static IconData trendIcon(String t) {
    switch (t) {
      case 'up':   return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default:     return Icons.trending_flat_rounded;
    }
  }

  static String trendLabel(String t) {
    switch (t) {
      case 'up':   return 'Rising';
      case 'down': return 'Falling';
      default:     return 'Steady';
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

              // ── Emergency alert bar ──────────────────────────────────────
              if (_emergencyCount > 0)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.35), width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_rounded, color: Color(0xFFE63946), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          GuardianMockData.patients
                              .where((p) => p.overallStatus == 'emergency')
                              .map((p) => p.name)
                              .join(', ') +
                              ' need${_emergencyCount == 1 ? 's' : ''} help right now',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE63946)),
                        ),
                      ),
                    ]),
                  ),
                ),

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
                          child: Icon(
                            Icons.tune_rounded,
                            color: _filterStatus != null ? Colors.white : Colors.grey.shade500,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_filterStatus != null)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 14, height: 14,
                            decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
                            child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
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
                    Text('Your Patients',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
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
                          onPressed: () => setState(() { _filterStatus = null; _query = ''; _searchCtrl.clear(); }),
                          child: const Text('Clear filters', style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700)),
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
  Widget _titleBlock() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Hello, Guardian',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C), letterSpacing: -0.5)),
    const SizedBox(height: 2),
    Text('Watching over ${GuardianMockData.patients.length} patients',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
  ]);

  // ── Status pills ───────────────────────────────────────────────────────────
  Widget _statusPills() => Wrap(spacing: 8, children: [
    _pill('${GuardianMockData.patients.length} Total', const Color(0xFF2A9D8F)),
    if (_emergencyCount > 0) _pill('$_emergencyCount Emergency', const Color(0xFFE63946)),
    if (_attentionCount > 0) _pill('$_attentionCount Attention', const Color(0xFFE76F51)),
  ]);

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  // ── Patient card ───────────────────────────────────────────────────────────
  Widget _buildCard(GuardianPatient p) {
    final sColor = statusColor(p.overallStatus);
    final gColor = glucoseColor(p);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: p.overallStatus != 'good'
            ? Border.all(color: sColor.withValues(alpha: 0.4), width: 1.5)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [

        // ── Identity row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: sColor.withValues(alpha: 0.12),
              child: Text(p.name.substring(0, 1),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: sColor)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
              const SizedBox(height: 2),
              Text('${p.relationship}  ·  Age ${p.age}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel(p.overallStatus),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sColor)),
            ),
          ]),
        ),

        // ── Glucose strip ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text('${p.glucoseValue}',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: gColor, letterSpacing: -1)),
            const SizedBox(width: 4),
            Text('mg/dL', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gColor.withValues(alpha: 0.1),
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
            // Device dots
            _dot(p.sensorConnected, 'Sensor'),
            const SizedBox(width: 4),
            _dot(p.pumpActive, 'Pump'),
            const SizedBox(width: 8),
            Text(p.lastSeenTime, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ]),
        ),

        // ── Devices legend (only when something offline) ──
        if (!p.sensorConnected || !p.pumpActive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              if (!p.sensorConnected) _warningChip('Sensor offline'),
              if (!p.sensorConnected && !p.pumpActive) const SizedBox(width: 6),
              if (!p.pumpActive) _warningChip('Pump paused'),
            ]),
          ),

        // ── Actions ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            _actionBtn(Icons.call_rounded, 'Call', const Color(0xFF2A9D8F),
                () { HapticFeedback.mediumImpact(); _snack('Calling ${p.name}...', const Color(0xFF2A9D8F)); }),
            const SizedBox(width: 8),
            _actionBtn(Icons.sms_rounded, 'SMS', const Color(0xFFE76F51),
                () => _snack('Opening SMS for ${p.name}...', const Color(0xFFE76F51))),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => GuardianPatientDetailScreen(patient: p),
              )),
              child: Row(children: [
                Text('View details',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(bool ok, String _) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
      color: ok ? const Color(0xFF2A9D8F) : const Color(0xFFE63946),
      shape: BoxShape.circle,
    ),
  );

  Widget _warningChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFE63946).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFE63946), fontWeight: FontWeight.w700)),
  );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Filter by Status',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C))),
          if (_sel != null)
            TextButton(
              onPressed: () { setState(() => _sel = null); widget.onApply(null); Navigator.pop(context); },
              child: const Text('Clear', style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 16),
        _opt(null,          'All Patients',      'Show everyone',                     Colors.grey),
        const SizedBox(height: 8),
        _opt('good',        'Doing Well',        'Sugar is in the normal range',      const Color(0xFF2A9D8F)),
        const SizedBox(height: 8),
        _opt('attention',   'Needs Attention',   'Sugar slightly out of range',       const Color(0xFFE76F51)),
        const SizedBox(height: 8),
        _opt('emergency',   'Needs Help Now',    'Urgent — act immediately',          const Color(0xFFE63946)),
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

  Widget _opt(String? value, String title, String subtitle, Color color) {
    final active = _sel == value;
    return GestureDetector(
      onTap: () => setState(() => _sel = (active && value != null) ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : Colors.grey.shade200,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: active ? color : const Color(0xFF1A2B3C))),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
          if (active) Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}