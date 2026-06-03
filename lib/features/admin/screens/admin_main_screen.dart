// =============================================================================
// AdminMainScreen
// =============================================================================
// This is the root shell widget for the entire admin section of the app.
// It owns the bottom navigation bar and acts as a tab controller — rendering
// one of three top-level screens (Dashboard, More, Account) based on which
// tab the admin has selected.
//
// Why a StatefulWidget here?
//   The currently selected tab index (_currentIndex) is mutable UI state that
//   needs to survive rebuilds, so StatefulWidget is the correct choice.
//   If we used StatelessWidget we couldn't call setState to switch tabs.
// =============================================================================

import 'package:flutter/material.dart';
import '../screens/admin_dashboard_screen.dart';
import 'admin_more_screen.dart';
import 'admin_account_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // Tracks which bottom-nav tab is currently active.
  // 0 = Dashboard, 1 = More, 2 = Account.
  int _currentIndex = 0;

  // Pre-built list of the three top-level admin screens.
  //
  // Using a fixed `const` list means Flutter creates these widget objects
  // once and never re-instantiates them when _currentIndex changes — the
  // Scaffold's `body` simply swaps which one is visible. This preserves
  // each screen's scroll position and state while the admin navigates tabs.
  final List<Widget> _screens = const [
    AdminDashboardScreen(), // Tab 0 – high-level system stats
    AdminMoreScreen(),      // Tab 1 – links to user/device/alert management
    AdminAccountScreen(),   // Tab 2 – admin's own profile & settings
  ];

  @override
  Widget build(BuildContext context) {
    // Pull the app-wide design-token colors from the theme extension so the
    // nav bar accent/unselected colors stay consistent with the rest of the UI.
    final colors = context.colors;

    return Scaffold(
      // Show whichever screen corresponds to the selected tab index.
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        // Highlight the active tab with the brand accent color.
        selectedItemColor: colors.accent,

        // Dim inactive tabs with a neutral grey so the active tab stands out.
        unselectedItemColor: Colors.grey,

        // `fixed` type keeps all labels visible at all times (as opposed to
        // `shifting` which hides labels on inactive tabs and uses a colored
        // background for the active one). Fixed is preferred here because
        // there are only 3 tabs and the labels add useful context.
        type: BottomNavigationBarType.fixed,

        // Rebuild with the new index whenever the admin taps a tab.
        onTap: (index) => setState(() => _currentIndex = index),

        items: const [
          BottomNavigationBarItem(
            // Outlined icon for inactive, filled icon for active — a standard
            // Material convention to give clear visual feedback.
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}