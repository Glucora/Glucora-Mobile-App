// =============================================================================
// AdminMoreScreen
// =============================================================================
// The second tab of AdminMainScreen. Acts as a navigation hub that links to
// the specialised admin management screens: Users, Devices, and Alert Rules.
//
// This screen has no state of its own — it's a pure navigation menu built with
// StatelessWidget. All heavy data loading happens in the destination screens.
//
// Layout:
//   Two section groups ("User Management" and "Device & Alert Management")
//   each contain one or more tappable menu cards. Grouping related actions
//   under section headers keeps the menu scannable as more items are added.
// =============================================================================

import 'package:flutter/material.dart';
import 'admin_user_list_screen.dart';
import 'admin_device_list_screen.dart';
import 'admin_alert_rules_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: colors.background,

      // ListView allows the menu to scroll if more sections/cards are added
      // in the future without requiring layout changes.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User Management section ─────────────────────────────────────
          _sectionTitle(context, 'User Management'),
          const SizedBox(height: 8),

          _menuCard(
            context,
            icon:     Icons.people,
            color:    colors.accent,
            title:    'Users',
            subtitle: 'Create, edit, delete user accounts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminUserListScreen()),
            ),
          ),

          const SizedBox(height: 24),

          // ── Device & Alert Management section ───────────────────────────
          _sectionTitle(context, 'Device & Alert Management'),
          const SizedBox(height: 8),

          _menuCard(
            context,
            icon:     Icons.sensors,
            color:    colors.warning,
            title:    'Devices',
            subtitle: 'Manage CGM sensors and micropumps',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminDeviceListScreen()),
            ),
          ),
          const SizedBox(height: 10),

          _menuCard(
            context,
            icon:     Icons.rule,
            color:    colors.error,
            title:    'Alert Rules',
            subtitle: 'Configure alert thresholds and conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminAlertRulesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Private helper widgets ─────────────────────────────────────────────────

  /// Section header label that visually groups related menu cards.
  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return TranslatedText(
      title,
      style: TextStyle(
        fontSize:   16,
        fontWeight: FontWeight.bold,
        color:      colors.primaryDark,
      ),
    );
  }

  /// A tappable card that navigates to a management screen when pressed.
  ///
  /// Parameters:
  ///   [icon]     — leading icon representing the section (e.g. people, sensors)
  ///   [color]    — accent colour for the icon and its background badge; each
  ///                section uses a distinct colour for quick visual scanning
  ///   [title]    — short destination name (e.g. "Users")
  ///   [subtitle] — one-line description of what the destination does
  ///   [onTap]    — navigation callback executed when the card is pressed
  ///
  /// Material + InkWell combination gives us the surface colour from Material
  /// and the ripple splash effect from InkWell. Using `borderRadius` on both
  /// ensures the ripple is clipped to the rounded rectangle, not the bounding box.
  Widget _menuCard(
    BuildContext context, {
    required IconData    icon,
    required Color       color,
    required String      title,
    required String      subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return Material(
      color:        colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap:        onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Coloured icon badge — matches the accent colour of the
              // destination screen for visual continuity between menu and page.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 26),
              ),

              const SizedBox(width: 14),

              // Title and subtitle — Expanded pushes the chevron to the far
              // right regardless of how long the text is.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Trailing chevron — the standard affordance indicating "tap to
              // navigate". Consistent with list items throughout the app.
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}