// =============================================================================
// AdminAlertRulesScreen
// =============================================================================
// Displays all system-level alerts (e.g. high/low glucose readings, sensor
// disconnects, pump failures) that have been generated and stored in Supabase.
// The admin can filter alerts by severity and delete individual entries.
//
// State management:
//   Alerts are loaded and cached in the Riverpod `adminAlertsProvider`
//   (an AsyncNotifier / StateNotifier). This screen is a ConsumerStatefulWidget
//   so it can both watch the provider for reactive rebuilds AND call
//   `ref.read(...)` inside async callbacks (initState, button handlers).
//
// Filtering:
//   _severityFilter is held in local widget state rather than the provider
//   because it is purely a UI concern — it does not affect what is fetched
//   from the server, only what the list renders.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/core/models/admin_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/providers/admin_riverpod_providers.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminAlertRulesScreen extends ConsumerStatefulWidget {
  const AdminAlertRulesScreen({super.key});

  @override
  ConsumerState<AdminAlertRulesScreen> createState() =>
      _AdminAlertRulesScreenState();
}

class _AdminAlertRulesScreenState
    extends ConsumerState<AdminAlertRulesScreen> {
  // Current severity chip selection. 'All' shows every alert regardless of
  // severity; 'Critical' or 'Warning' narrow the list.
  String _severityFilter = 'All';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Defer the load to a microtask so it runs after the first frame.
    // Calling ref.read inside initState directly is safe in Riverpod but
    // wrapping in microtask avoids any provider-during-build edge cases.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(adminAlertsProvider.notifier).loadAlerts();
    });
  }

  // ── Filtering helper ───────────────────────────────────────────────────────

  /// Returns a filtered copy of [alerts] based on the active severity chip.
  /// Case-insensitive comparison makes the filter robust against mixed-case
  /// data from the server.
  List<AdminAlert> _filtered(List<AdminAlert> alerts) {
    if (_severityFilter == 'All') return alerts;
    return alerts
        .where((a) =>
            a.severity.toLowerCase() == _severityFilter.toLowerCase())
        .toList();
  }

  // ── Delete handler ─────────────────────────────────────────────────────────

  /// Shows a confirmation dialog before deleting [alert]. If confirmed,
  /// dispatches the delete action through the notifier and shows a SnackBar
  /// to report success or failure.
  Future<void> _deleteAlert(AdminAlert alert) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Delete Alert'),
        content: TranslatedText(
            'Are you sure you want to delete "${alert.title}"?'),
        actions: [
          // Cancel — dismiss without doing anything.
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const TranslatedText('Cancel')),

          // Confirm delete — pop the dialog first, then perform the async
          // operation so there's no "navigator in a disposed widget" risk.
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(adminAlertsProvider.notifier)
                  .deleteAlert(alert.id);

              // After the await, check mounted again because the screen may
              // have been left while the delete was in flight.
              if (mounted) {
                final error = ref.read(adminAlertsProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      TranslatedText(error ?? 'Alert deleted successfully'),
                  backgroundColor: error != null ? Colors.red : Colors.green,
                ));
                // Clear the error from the provider so it doesn't persist
                // into the next action.
                if (error != null) {
                  ref.read(adminAlertsProvider.notifier).clearError();
                }
              }
            },
            child: const TranslatedText('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Visual helpers ─────────────────────────────────────────────────────────

  /// Maps a severity string to a colour used for the badge, icon background,
  /// and icon tint, so the visual hierarchy matches the urgency of the alert.
  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F); // Deep red — immediate attention.
      case 'warning':
        return const Color(0xFFFF9F40); // Amber — elevated concern.
      default:
        return Colors.grey; // Unknown severity — neutral.
    }
  }

  /// Picks an icon that communicates the alert's type at a glance, reducing
  /// the cognitive load of reading the text title for common alert types.
  IconData _alertTypeIcon(String alertType) {
    switch (alertType) {
      case 'high_glucose':       return Icons.arrow_upward;
      case 'low_glucose':        return Icons.arrow_downward;
      case 'sensor_disconnect':  return Icons.sensors_off;
      case 'pump_failure':       return Icons.warning_amber;
      case 'missed_dose':        return Icons.schedule;
      default:                   return Icons.notifications;
    }
  }

  /// Formats a nullable DateTime into a human-readable "dd/mm/yyyy  HH:mm"
  /// string. Returns an em-dash for null dates (alert hasn't been triggered).
  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Watch the provider; the widget rebuilds whenever the alerts list,
    // loading state, or error state changes.
    final state    = ref.watch(adminAlertsProvider);
    final filtered = _filtered(state.alerts);

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Alerts',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Manual refresh button — useful after resolving an alert externally.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminAlertsProvider.notifier).loadAlerts(),
            tooltip: 'Refresh',
          ),
        ],
      ),

      backgroundColor: colors.background,

      body: state.isLoading
          // Full-screen spinner while the initial data loads.
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Severity filter chips ───────────────────────────────────
                // A horizontal scrollable row of FilterChips lets the admin
                // narrow the list without navigating to a separate filter screen.
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children:
                        ['All', 'Critical', 'Warning'].map((label) {
                      final selected = _severityFilter == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: TranslatedText(label,
                              style:
                                  TextStyle(color: colors.textPrimary)),
                          selected: selected,
                          // Accent background tint when selected.
                          selectedColor:
                              colors.accent.withValues(alpha: 0.2),
                          checkmarkColor: colors.accent,
                          onSelected: (_) =>
                              setState(() => _severityFilter = label),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Alerts list ─────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: TranslatedText('No alerts',
                              style: TextStyle(
                                  color: colors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          // 8-pt gap between cards keeps them visually
                          // separated without wasting screen space.
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _alertCard(context, filtered[index]),
                        ),
                ),
              ],
            ),
    );
  }

  // ── Alert card ─────────────────────────────────────────────────────────────

  /// Builds a single alert list item. Layout:
  ///   [icon] | [title / message / date] | [severity badge, resolved badge] | [⋮]
  Widget _alertCard(BuildContext context, AdminAlert alert) {
    final colors = context.colors;
    final color  = _severityColor(alert.severity);

    return Material(
      color:        colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Alert type icon ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_alertTypeIcon(alert.alertType),
                  color: color, size: 24),
            ),

            const SizedBox(width: 12),

            // ── Text content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert title — bold for quick scanning.
                  TranslatedText(alert.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   14,
                          color:      colors.textPrimary)),
                  const SizedBox(height: 2),
                  // Alert message — truncated at 2 lines to keep cards compact.
                  TranslatedText(alert.message,
                      style: TextStyle(
                          fontSize: 11, color: colors.textSecondary),
                      maxLines:  2,
                      overflow:  TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  // Trigger timestamp — smaller and secondary since it's
                  // supplementary metadata rather than primary content.
                  TranslatedText(_formatDate(alert.triggeredAt),
                      style: TextStyle(
                          fontSize: 10, color: colors.textSecondary)),
                ],
              ),
            ),

            // ── Badges column ────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Severity badge (e.g. "Critical" / "Warning").
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TranslatedText(alert.severity,
                      style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                          color:      color)),
                ),

                const SizedBox(height: 4),

                // "Resolved" badge — only shown when the alert has been
                // acknowledged/resolved (resolvedAt is non-null).
                if (alert.resolvedAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:        Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const TranslatedText('Resolved',
                        style: TextStyle(fontSize: 10, color: Colors.green)),
                  ),
              ],
            ),

            // ── Overflow menu ────────────────────────────────────────────────
            // Only "Delete" for now; future actions (e.g. "Mark Resolved")
            // can be added here without changing the card layout.
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deleteAlert(alert);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'delete',
                    child: TranslatedText('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}