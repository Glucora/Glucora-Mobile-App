import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GuardianAlert {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final String urgency;
  final String emoji;
  bool isRead;

  GuardianAlert({required this.id, required this.title, required this.description, required this.timeAgo, required this.urgency, required this.emoji, this.isRead = false});
}

class GuardianAlertsScreen extends StatefulWidget {
  const GuardianAlertsScreen({super.key});
  @override
  State<GuardianAlertsScreen> createState() => _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState extends State<GuardianAlertsScreen> {
  final List<GuardianAlert> _alerts = [
    GuardianAlert(id: '1', title: "Ahmed's sugar is dangerously high", description: 'His blood sugar went very high and the device gave him extra insulin automatically. Keep an eye on him and consider calling.', timeAgo: '3 min ago', urgency: 'emergency', emoji: 'Emergency'),
    GuardianAlert(id: '2', title: "Ahmed's sugar dropped too low", description: "His blood sugar fell quite low. The device paused insulin to help. He may need to eat or drink something sweet right away.", timeAgo: '8 min ago', urgency: 'emergency', emoji: 'Low Sugar'),
    GuardianAlert(id: '3', title: 'Pump lost connection', description: 'The insulin pump got disconnected for a short time. It has been working in manual mode. This is being monitored.', timeAgo: '25 min ago', urgency: 'warning', emoji: 'Device'),
    GuardianAlert(id: '4', title: "Ahmed didn't log lunch", description: 'No meal was recorded around lunchtime. His sugar rose a little afterwards. You might want to check in with him.', timeAgo: '1 hour ago', urgency: 'warning', emoji: 'Meal'),
    GuardianAlert(id: '5', title: 'Sensor disconnected briefly', description: 'The glucose sensor lost signal for about 38 minutes but reconnected on its own. Everything is back to normal now.', timeAgo: '3 hours ago', urgency: 'warning', emoji: 'Sensor', isRead: true),
    GuardianAlert(id: '6', title: 'Sugar has been a bit high today', description: 'Ahmed spent more time than usual with high sugar levels today. His doctor has been informed and may adjust his plan.', timeAgo: '5 hours ago', urgency: 'info', emoji: 'Report', isRead: true),
    GuardianAlert(id: '7', title: 'No reading for 4 hours', description: "The sensor hasn't sent a reading in a while. The sensor might be old or fell off. Ahmed may need to replace it.", timeAgo: '6 hours ago', urgency: 'info', emoji: 'Inactivity', isRead: true),
  ];

  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Emergency', 'Warning', 'Info'];

  List<GuardianAlert> get _visible {
    return _alerts.where((a) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == ' Emergency') return a.urgency == 'emergency';
      if (_activeFilter == ' Warning') return a.urgency == 'warning';
      if (_activeFilter == 'ℹ Info') return a.urgency == 'info';
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
        const order = {'emergency': 0, 'warning': 1, 'info': 2};
        return (order[a.urgency] ?? 2).compareTo(order[b.urgency] ?? 2);
      });
  }

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;

  Color _urgencyColor(String u) {
    switch (u) {
      case 'emergency': return const Color(0xFFE63946);
      case 'warning':   return const Color(0xFFE76F51);
      default:          return const Color(0xFF5B8CF5);
    }
  }

  void _markRead(GuardianAlert a) => setState(() => a.isRead = true);
  void _markAllRead() => setState(() { for (final a in _alerts) { a.isRead = true; } });

  void _callPatient() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Calling Ahmed...', style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF2A9D8F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: OrientationBuilder(builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, isLandscape ? 12 : 24, 20, 0),
                  child: isLandscape
                      ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Expanded(child: _titleBlock()),
                          const SizedBox(width: 16),
                          _filterRow(),
                        ])
                      : _titleBlock(),
                ),
              ),
              if (!isLandscape)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const ClampingScrollPhysics(),
                        itemCount: _filters.length,
                        separatorBuilder: (_, _i) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => _chip(_filters[i]),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              if (visible.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('All clear! No alerts right now.', style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              if (visible.isNotEmpty)
                isLandscape
                    ? SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 0, mainAxisExtent: 210),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _AlertCard(alert: visible[i], urgencyColor: _urgencyColor(visible[i].urgency), onMarkRead: () => _markRead(visible[i]), onCall: _callPatient),
                            childCount: visible.length,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _AlertCard(alert: visible[i], urgencyColor: _urgencyColor(visible[i].urgency), onMarkRead: () => _markRead(visible[i]), onCall: _callPatient),
                            childCount: visible.length,
                          ),
                        ),
                      ),
            ],
          );
        }),
      ),
    );
  }

  Widget _titleBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C), letterSpacing: -0.5))),
        if (_unreadCount > 0)
          TextButton(onPressed: _markAllRead, child: const Text('Mark all seen', style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
      const SizedBox(height: 4),
      _unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('$_unreadCount new', style: const TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w700, fontSize: 12)),
            )
          : Text('All caught up ', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
    ]);
  }

  Widget _filterRow() => Row(mainAxisSize: MainAxisSize.min, children: _filters.map((f) => Padding(padding: const EdgeInsets.only(left: 8), child: _chip(f))).toList());

  Widget _chip(String filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A9D8F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(filter, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : Colors.grey.shade500)),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final GuardianAlert alert;
  final Color urgencyColor;
  final VoidCallback onMarkRead;
  final VoidCallback onCall;

  const _AlertCard({required this.alert, required this.urgencyColor, required this.onMarkRead, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: alert.isRead ? null : Border.all(color: urgencyColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(color: urgencyColor.withValues(alpha: 0.07), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(children: [
            Text(alert.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Text(alert.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: alert.isRead ? const Color(0xFF1A2B3C) : urgencyColor, letterSpacing: -0.2, height: 1.3))),
            if (!alert.isRead)
              Container(width: 9, height: 9, decoration: BoxDecoration(color: urgencyColor, shape: BoxShape.circle)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(alert.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Row(children: [
            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(alert.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (!alert.isRead)
              _btn(Icons.check_rounded, 'Got it', Colors.grey.shade600, Colors.grey.shade100, onMarkRead),
            if (alert.urgency == 'emergency') ...[
              const SizedBox(width: 8),
              _btn(Icons.call_rounded, 'Call Ahmed', Colors.white, urgencyColor, onCall),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}