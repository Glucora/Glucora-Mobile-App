import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guardian_patient_model.dart';
import 'guardian_patient_detail_screen.dart';

class _Alert {
  final String id;
  final String patientId;
  final String patientName;
  final String title;
  final String description;
  final String timeAgo;
  final String urgency; // 'emergency' | 'warning' | 'info'
  final String typeLabel;
  bool isRead;

  _Alert({required this.id, required this.patientId, required this.patientName,
    required this.title, required this.description, required this.timeAgo,
    required this.urgency, required this.typeLabel, this.isRead = false});
}

class GuardianAlertsScreen extends StatefulWidget {
  const GuardianAlertsScreen({super.key});
  @override
  State<GuardianAlertsScreen> createState() => _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState extends State<GuardianAlertsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _urgencyFilter = 'All';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  final List<_Alert> _alerts = [
    _Alert(id: 'a1', patientId: 'p3', patientName: 'Grandma Fatma',
        title: "Grandma Fatma's sugar dropped too low",
        description: 'Her blood sugar fell to a dangerous level. The device paused insulin to help. She may need something sweet to eat right away.',
        timeAgo: '1 min ago', urgency: 'emergency', typeLabel: 'LOW SUGAR'),
    _Alert(id: 'a2', patientId: 'p2', patientName: 'Sara',
        title: "Sara's sugar is a bit high",
        description: 'Her blood sugar has been rising since lunch. The device is giving extra insulin automatically. Keep an eye on her.',
        timeAgo: '8 min ago', urgency: 'warning', typeLabel: 'HIGH SUGAR'),
    _Alert(id: 'a3', patientId: 'p3', patientName: 'Grandma Fatma',
        title: "Grandma Fatma's pump is not active",
        description: "The insulin pump appears to be paused. She may need manual insulin. Check with her or her doctor.",
        timeAgo: '15 min ago', urgency: 'emergency', typeLabel: 'PUMP'),
    _Alert(id: 'a4', patientId: 'p1', patientName: 'Ahmed',
        title: 'Ahmed has been in a good range all day',
        description: 'His blood sugar has stayed in the safe zone for the past 8 hours. Everything is running automatically.',
        timeAgo: '2 hours ago', urgency: 'info', typeLabel: 'UPDATE', isRead: true),
    _Alert(id: 'a5', patientId: 'p2', patientName: 'Sara',
        title: "Sara's sensor disconnected briefly",
        description: 'The glucose sensor lost signal for about 20 minutes but reconnected. No action needed.',
        timeAgo: '3 hours ago', urgency: 'warning', typeLabel: 'SENSOR', isRead: true),
    _Alert(id: 'a6', patientId: 'p1', patientName: 'Ahmed',
        title: 'Ahmed has a doctor visit coming up',
        description: 'His next appointment with Dr. Nouran is on April 2nd. You may want to remind him.',
        timeAgo: '5 hours ago', urgency: 'info', typeLabel: 'REMINDER', isRead: true),
  ];

  List<_Alert> get _filtered => _alerts.where((a) {
    final q = _query.toLowerCase();
    final matchQ = q.isEmpty ||
        a.patientName.toLowerCase().contains(q) ||
        a.title.toLowerCase().contains(q);
    final matchU = _urgencyFilter == 'All' ||
        (_urgencyFilter == 'Emergency' && a.urgency == 'emergency') ||
        (_urgencyFilter == 'Warning'   && a.urgency == 'warning') ||
        (_urgencyFilter == 'Info'      && a.urgency == 'info');
    return matchQ && matchU;
  }).toList()
    ..sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      const o = {'emergency': 0, 'warning': 1, 'info': 2};
      return (o[a.urgency] ?? 2).compareTo(o[b.urgency] ?? 2);
    });

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;

  Color _uColor(String u) {
    switch (u) {
      case 'emergency': return const Color(0xFFE63946);
      case 'warning':   return const Color(0xFFE76F51);
      default:          return const Color(0xFF2A9D8F);
    }
  }

  void _markRead(_Alert a)  => setState(() => a.isRead = true);
  void _markAllRead()       => setState(() { for (final a in _alerts) a.isRead = true; });

  void _call(String name) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Calling $name...', style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF2A9D8F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  GuardianPatient? _patientById(String id) {
    try { return GuardianMockData.patients.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
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

              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, isLandscape ? 10 : 24, 20, 0),
                  child: isLandscape
                      ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Expanded(child: _headerBlock()),
                          const SizedBox(width: 16),
                          _filterChips(),
                        ])
                      : _headerBlock(),
                ),
              ),

              // ── Search bar ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                        hintText: 'Search alerts or patient name...',
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
              ),

              // ── Filter chips (portrait only) ───────────────────────────────
              if (!isLandscape)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const ClampingScrollPhysics(),
                        children: ['All', 'Emergency', 'Warning', 'Info']
                            .map((f) => _chip(f))
                            .toList(),
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(children: [
                    Text('${list.length} alert${list.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    const Spacer(),
                    if (_unreadCount > 0)
                      TextButton(
                        onPressed: _markAllRead,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text('Mark all seen',
                            style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                  ]),
                ),
              ),

              // ── Empty ──────────────────────────────────────────────────────
              if (list.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No alerts found.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  ])),
                ),

              // ── Alert cards ────────────────────────────────────────────────
              if (list.isNotEmpty)
                isLandscape
                    ? SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 14, mainAxisExtent: 220,
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

  Widget _headerBlock() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
          color: Color(0xFF1A2B3C), letterSpacing: -0.5)),
      const Spacer(),
    ]),
    const SizedBox(height: 4),
    _unreadCount > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$_unreadCount new',
                style: const TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w700, fontSize: 12)))
        : Text('All caught up', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    const SizedBox(height: 4),
  ]);

  Widget _filterChips() => Row(mainAxisSize: MainAxisSize.min, children:
      ['All', 'Emergency', 'Warning', 'Info'].map((f) => Padding(
        padding: const EdgeInsets.only(left: 8), child: _chip(f))).toList());

  Widget _chip(String label) {
    final active = _urgencyFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _urgencyFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A9D8F) : const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.grey.shade500)),
      ),
    );
  }

  Widget _buildCard(_Alert a) {
    final uc = _uColor(a.urgency);
    final patient = _patientById(a.patientId);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: a.isRead
            ? Border.all(color: Colors.grey.shade100)
            : Border.all(color: uc.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card header ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: uc.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: uc.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(a.typeLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: uc, letterSpacing: 0.5)),
            ),
            const SizedBox(width: 8),
            // Patient name chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(a.patientName,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
            ),
            const Spacer(),
            if (!a.isRead)
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: uc, shape: BoxShape.circle)),
          ]),
        ),

        // ── Title + description ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(a.title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: a.isRead ? const Color(0xFF1A2B3C) : uc, height: 1.3)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text(a.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5)),
        ),

        // ── Time + actions ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Row(children: [
            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(a.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            const Spacer(),
            if (!a.isRead)
              _btn(Icons.check_rounded, 'Got it', Colors.grey.shade600, Colors.grey.shade100, () => _markRead(a)),
            if (a.urgency == 'emergency') ...[
              const SizedBox(width: 8),
              _btn(Icons.call_rounded, 'Call', Colors.white, uc, () => _call(a.patientName)),
            ],
            if (patient != null) ...[
              const SizedBox(width: 8),
              _btn(Icons.person_outline_rounded, 'View', const Color(0xFF2A9D8F),
                  const Color(0xFF2A9D8F).withValues(alpha: 0.1), () {
                _markRead(a);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GuardianPatientDetailScreen(patient: patient),
                ));
              }),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, Color color, Color bg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );
}