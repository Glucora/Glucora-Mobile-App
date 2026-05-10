// lib\features\patient\widgets\patient_navigation.dart
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/features/patient/screens/calorie_log_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/home_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/manual_log_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/medication_screen.dart';
import 'package:glucora_ai_companion/features/patient/widgets/patient_profile_tab.dart';
import 'nav_tab_item.dart';
import 'nav_tile.dart';

// ─────────────────────────────────────────────────────────────
// PatientNavigation
//
// Responsibilities:
//   • Owns the bottom navigation state (selected index).
//   • Delegates rendering of each tab to named widgets.
//   • Delegates nav-bar item appearance to _NavTile.
// ─────────────────────────────────────────────────────────────
class PatientNavigation extends StatefulWidget {
  const PatientNavigation({super.key});

  @override
  State<PatientNavigation> createState() => _PatientNavigationState();
}

class _PatientNavigationState extends State<PatientNavigation> {
  int _currentIndex = 0;

  // Screens are constant – they never rebuild when the index changes.
  final List<Widget> _screens = [
    HomeScreen(),
    CalorieLogScreen(),
    ManualLogScreen(),
    MedicationScreen(),
    PatientProfileTab(),
  ];

  // Declarative tab descriptors – single source of truth.
  static const List<NavTabItem> _tabs = [
    NavTabItem(icon: Icons.home_rounded, label: 'Home'),
    NavTabItem(icon: Icons.restaurant_menu_rounded, label: 'Calories'),
    NavTabItem(icon: Icons.edit_rounded, label: 'Log'),
    NavTabItem(icon: Icons.medication_rounded, label: 'Meds'),
    NavTabItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LocalizedDirectionality(
      child: Scaffold(
        backgroundColor: colors.background,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _PatientNavBar(
          tabs: _tabs,
          currentIndex: _currentIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _PatientNavBar  (private – only PatientNavigation needs it)
// ─────────────────────────────────────────────────────────────
class _PatientNavBar extends StatelessWidget {
  final List<NavTabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _PatientNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.textSecondary.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(tabs.length, (i) {
              return NavTile(
                item: tabs[i],
                active: currentIndex == i,
                onTap: () => onTabSelected(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}
