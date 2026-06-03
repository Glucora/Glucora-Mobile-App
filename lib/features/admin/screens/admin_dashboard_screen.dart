// =============================================================================
// AdminDashboardScreen
// =============================================================================
// The first tab of AdminMainScreen. Shows a bird's-eye view of the entire
// system: how many users of each role exist, how many devices are active or
// inactive, and how many unresolved alerts are pending.
//
// Data is pulled from three Riverpod providers:
//   • adminUsersProvider   – full user list + loading/error state
//   • adminDevicesProvider – full device list + loading/error state
//   • adminAlertsProvider  – full alert list + loading/error state
//
// The `adminDashboardProvider` is a combined provider (presumably a
// Provider<AdminDashboardState> that watches all three) used here so a single
// `ref.watch` gives us all three sub-states in one object, which simplifies
// the derived loading/error check.
//
// Why ConsumerStatefulWidget?
//   initState needs to trigger data loads via `ref.read(...)` and `_reload`
//   needs to be wired to a button. Either of those alone would justify using
//   ConsumerStateful over ConsumerWidget.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/providers/admin_riverpod_providers.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Kick off all three data loads asynchronously after the first frame.
    // Using Future.microtask avoids calling ref.read during a build phase,
    // which can happen if this widget is part of the initial widget tree.
    Future.microtask(() {
      ref.read(adminUsersProvider.notifier).loadUsers();
      ref.read(adminDevicesProvider.notifier).loadDevices();
      ref.read(adminAlertsProvider.notifier).loadAlerts();
    });
  }

  // ── Reload ─────────────────────────────────────────────────────────────────

  /// Refreshes all three data sources simultaneously. Wired to the AppBar
  /// refresh button and the Retry button in the error state.
  void _reload() {
    ref.read(adminUsersProvider.notifier).loadUsers();
    ref.read(adminDevicesProvider.notifier).loadDevices();
    ref.read(adminAlertsProvider.notifier).loadAlerts();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Watch the combined dashboard provider. Rebuilds whenever any of the
    // three sub-providers change (loading state, new data, or an error).
    final dashboard = ref.watch(adminDashboardProvider);
    final users     = dashboard.users;
    final devices   = dashboard.devices;
    final alerts    = dashboard.alerts;

    // The dashboard is considered "loading" if any one of its data sources
    // is still fetching. A single spinner covers all three states at once.
    final isLoading = users.isLoading || devices.isLoading || alerts.isLoading;

    // Surface the first non-null error from any provider. In practice all
    // three would likely fail together (e.g. auth expired), but showing the
    // first is sufficient to prompt the admin to retry.
    final error = users.error ?? devices.error ?? alerts.error;

    // Derive role-specific sub-lists from the flat users list so we can show
    // per-role counts. This computation is cheap (linear scan) and does not
    // need memoisation at this scale.
    final patients  = users.users.where((u) => u.role == 'patient').toList();
    final doctors   = users.users.where((u) => u.role == 'doctor').toList();
    final guardians = users.users.where((u) => u.role == 'guardian').toList();

    // ── Loading state ──────────────────────────────────────────────────────
    if (isLoading) {
      return Scaffold(
        // Pass null for onRefresh so the AppBar doesn't show the refresh
        // button while data is already loading.
        appBar: _appBar(colors, null),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error state ────────────────────────────────────────────────────────
    if (error != null) {
      return Scaffold(
        appBar: _appBar(colors, null),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Failed to load data',
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _reload,
                child: const TranslatedText('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Success state ──────────────────────────────────────────────────────
    return Scaffold(
      appBar: _appBar(colors, _reload), // Refresh button visible when loaded.
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── System Overview section ─────────────────────────────────────
            _sectionTitle(context, 'System Overview'),
            const SizedBox(height: 12),

            // Two-column row: Total Users | Patients
            Row(children: [
              Expanded(
                child: _statCard(context, 'Total Users',
                    '${users.totalUsers}', Icons.people, colors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(context, 'Patients', '${patients.length}',
                    Icons.personal_injury, const Color(0xFF5B8CF5)),
              ),
            ]),
            const SizedBox(height: 12),

            // Two-column row: Doctors | Guardians
            Row(children: [
              Expanded(
                child: _statCard(context, 'Doctors', '${doctors.length}',
                    Icons.medical_services, const Color(0xFF9B59B6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(context, 'Guardians', '${guardians.length}',
                    Icons.family_restroom, const Color(0xFF2BB6A3)),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Devices section ─────────────────────────────────────────────
            _sectionTitle(context, 'Devices'),
            const SizedBox(height: 12),

            // Two-column row: Active | Inactive
            Row(children: [
              Expanded(
                child: _statCard(context, 'Active',
                    '${devices.activeDevices}', Icons.sensors, colors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(context, 'Inactive',
                    '${devices.inactiveDevices}', Icons.sensors_off,
                    colors.error),
              ),
            ]),
            const SizedBox(height: 12),

            // Full-width total devices card.
            _statCard(context, 'Total Devices', '${devices.totalDevices}',
                Icons.device_hub, const Color(0xFF5B8CF5)),

            const SizedBox(height: 24),

            // ── Alerts section ──────────────────────────────────────────────
            _sectionTitle(context, 'Alerts'),
            const SizedBox(height: 12),

            // Full-width alert count — tapping could navigate to the alert
            // list in a future iteration.
            _statCard(context, 'Alerts', '${alerts.alerts.length}',
                Icons.warning_amber, colors.error),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  /// Builds the screen's AppBar. The refresh button is conditionally included
  /// via [onRefresh]; passing null hides it (used during loading/error states).
  AppBar _appBar(dynamic colors, VoidCallback? onRefresh) {
    return AppBar(
      title: const TranslatedText('Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: colors.primaryDark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
      ],
    );
  }

  /// Section header label (e.g. "System Overview", "Devices", "Alerts").
  /// Styled with primaryDark so it visually anchors each group of stat cards.
  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return TranslatedText(title,
        style: TextStyle(
            fontSize:   18,
            fontWeight: FontWeight.bold,
            color:      colors.primaryDark));
  }

  /// A stat card showing a coloured icon, a large numeric value, and a label.
  ///
  /// Parameters:
  ///   [label] — descriptive text below the number (e.g. "Active Devices")
  ///   [value] — the string representation of the stat (e.g. "42")
  ///   [icon]  — Material icon representing the category
  ///   [color] — accent colour used for both the icon and the number; each
  ///             category uses a distinct colour so cards are scannable at
  ///             a glance without reading the label.
  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surface,
        borderRadius: BorderRadius.circular(16),
        // Subtle shadow to lift the card off the background.
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge — small coloured background square behind the icon.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          // The headline number — large and bold so it's readable at a glance.
          TranslatedText(value,
              style: TextStyle(
                  fontSize:   22,
                  fontWeight: FontWeight.bold,
                  color:      color)),
          const SizedBox(height: 4),
          // Category label — smaller and secondary.
          TranslatedText(label,
              style: TextStyle(
                  fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}