import 'package:flutter/material.dart';
import 'guardian_home_screen.dart';
import 'guardian_alerts_screen.dart';
import 'guardian_requests_screen.dart';

class GuardianMainScreen extends StatefulWidget {
  const GuardianMainScreen({super.key});
  @override
  State<GuardianMainScreen> createState() => _GuardianMainScreenState();
}

class _GuardianMainScreenState extends State<GuardianMainScreen> {
  int _index = 0;

  // Replace with real counts from backend
  static const int _unreadAlerts = 3;
  static const int _pendingRequests = 2;

  final List<Widget> _screens = const [
    GuardianHomeScreen(),
    GuardianAlertsScreen(),
    GuardianRequestsScreen(),
    _ProfilePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(0, Icons.home_rounded,             Icons.home_outlined,             'Home'),
                _item(1, Icons.notifications_rounded,    Icons.notifications_outlined,    'Alerts',    badge: _unreadAlerts),
                _item(2, Icons.people_rounded,           Icons.people_outline_rounded,    'Requests',  badge: _pendingRequests),
                _item(3, Icons.person_rounded,           Icons.person_outline_rounded,    'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int idx, IconData active, IconData inactive, String label, {int badge = 0}) {
    final sel = _index == idx;
    return GestureDetector(
      onTap: () => setState(() => _index = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF2A9D8F).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(sel ? active : inactive,
                color: sel ? const Color(0xFF2A9D8F) : Colors.grey.shade400, size: 26),
            if (badge > 0)
              Positioned(
                top: -4, right: -6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
                  child: Center(child: Text('$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? const Color(0xFF2A9D8F) : Colors.grey.shade400,
          )),
        ]),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Profile')),
    );
  }
}