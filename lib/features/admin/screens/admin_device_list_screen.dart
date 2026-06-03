// =============================================================================
// AdminDeviceListScreen
// =============================================================================
// Shows all registered medical devices (CGM sensors and insulin micropumps)
// with search and delete capabilities. The admin can search across device
// name, serial number, and assigned user name in real time, and delete devices
// via a confirmation dialog.
//
// State split:
//   • Device data (list, loading, error) lives in `adminDevicesProvider`
//     (Riverpod) so it's shared across screens and survives navigation.
//   • Search query (_query) is local widget state because it's purely a UI
//     filter that does not affect what is stored in the provider.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/core/models/admin_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/providers/admin_riverpod_providers.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminDeviceListScreen extends ConsumerStatefulWidget {
  const AdminDeviceListScreen({super.key});

  @override
  ConsumerState<AdminDeviceListScreen> createState() =>
      _AdminDeviceListScreenState();
}

class _AdminDeviceListScreenState
    extends ConsumerState<AdminDeviceListScreen> {
  // Controller for the search TextField. Enables reading the current text and
  // calling .clear() from the clear-button's onPressed callback.
  final TextEditingController _searchController = TextEditingController();

  // Current search string. Updated via TextField.onChanged so the list
  // re-filters on every keystroke without requiring a form submission.
  String _query = '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Load devices after the first frame. Microtask avoids calling ref.read
    // inside the build phase if this screen is part of the initial widget tree.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(adminDevicesProvider.notifier).loadDevices();
    });
  }

  @override
  void dispose() {
    // Release the TextEditingController to free platform input resources.
    _searchController.dispose();
    super.dispose();
  }

  // ── Search filter ──────────────────────────────────────────────────────────

  /// Returns the subset of [devices] whose name, assigned-user name, or
  /// serial number contains the current search [_query] (case-insensitive).
  /// An empty query returns the full list unchanged.
  List<AdminDevice> _filtered(List<AdminDevice> devices) {
    if (_query.isEmpty) return devices;
    return devices.where((d) {
      return d.deviceName.toLowerCase().contains(_query.toLowerCase()) ||
          d.assignedToUserName.toLowerCase().contains(_query.toLowerCase()) ||
          d.serialNumber.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  // ── Delete handler ─────────────────────────────────────────────────────────

  /// Shows a confirmation dialog then deletes [device] via the provider notifier.
  /// Reports the outcome (success or error string) in a SnackBar.
  Future<void> _deleteDevice(AdminDevice device) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Delete Device'),
        content: TranslatedText(
            'Are you sure you want to delete "${device.deviceName}"?'),
        actions: [
          // Cancel — dismiss the dialog without taking action.
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const TranslatedText('Cancel')),

          // Confirm — pop the dialog first so there's no navigator-on-disposed
          // risk, then perform the async delete operation.
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(adminDevicesProvider.notifier)
                  .deleteDevice(device.id);

              // Guard: user may have left the screen while the delete was in flight.
              if (mounted) {
                final error = ref.read(adminDevicesProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: TranslatedText(
                      error ?? 'Device deleted successfully'),
                  backgroundColor: error != null ? Colors.red : Colors.green,
                ));
                // Clear the stale error so it doesn't affect the next action.
                if (error != null) {
                  ref.read(adminDevicesProvider.notifier).clearError();
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors   = context.colors;
    final state    = ref.watch(adminDevicesProvider);
    final filtered = _filtered(state.devices);

    // Show a spinner inside the Scaffold (with the AppBar) while loading so
    // the user isn't greeted by a blank screen.
    if (state.isLoading) {
      return Scaffold(
        appBar: _appBar(colors, null), // No refresh button during loading.
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _appBar(colors,
          () => ref.read(adminDevicesProvider.notifier).loadDevices()),
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Search field ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:  'Search by name, serial, or user…',
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                // Show a clear (×) button only when the field has text so the
                // admin can reset the search with a single tap.
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        })
                    : null,
                filled:         true,
                fillColor:      colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide.none),
              ),
              // Update _query on every keystroke; setState triggers a rebuild
              // which re-runs _filtered with the new query.
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // ── Device list ───────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: TranslatedText('No devices found',
                        style: TextStyle(color: colors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _deviceCard(context, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Builds the shared AppBar. [onRefresh] is null during loading, which
  /// hides the refresh button via the conditional `if (onRefresh != null)`.
  AppBar _appBar(dynamic colors, VoidCallback? onRefresh) {
    return AppBar(
      title: const TranslatedText('Devices',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: colors.primaryDark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (onRefresh != null)
          IconButton(
              icon:    const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: 'Refresh'),
      ],
    );
  }

  /// Builds a single device card. Layout:
  ///   [device icon] | [name / model+serial / assigned user] | [type badge, inactive badge] | [⋮]
  ///
  /// CGM sensors and insulin micropumps are distinguished by colour and icon
  /// to give the admin an instant visual cue before reading the type text.
  Widget _deviceCard(BuildContext context, AdminDevice device) {
    final colors = context.colors;
    final isCGM  = device.deviceType == 'CGM';

    // CGM devices use the brand accent colour; insulin pumps use purple.
    final color = isCGM ? colors.accent : const Color(0xFF9B59B6);

    return Material(
      color:        colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Device type icon ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  isCGM ? Icons.sensors : Icons.medical_services,
                  color: color,
                  size: 24),
            ),

            const SizedBox(width: 12),

            // ── Device text details ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device display name — most prominent text in the card.
                  TranslatedText(device.deviceName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   14,
                          color:      colors.textPrimary)),
                  const SizedBox(height: 2),
                  // Model and serial on one line, separated by a bullet for
                  // compact presentation without adding extra rows.
                  TranslatedText(
                      '${device.model}  •  ${device.serialNumber}',
                      style: TextStyle(
                          fontSize: 11, color: colors.textSecondary)),
                  const SizedBox(height: 2),
                  // Assigned patient/user name so the admin can immediately
                  // tell which patient would be affected by changes.
                  TranslatedText(
                      'Assigned to: ${device.assignedToUserName}',
                      style: TextStyle(
                          fontSize: 11, color: colors.textSecondary)),
                ],
              ),
            ),

            // ── Status badges column ─────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Device type badge (e.g. "CGM" / "Pump").
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TranslatedText(device.deviceType,
                      style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                          color:      color)),
                ),
                const SizedBox(height: 4),
                // "Inactive" badge — shown only when the device is not
                // currently reporting / in use. Active devices don't need
                // a badge because "active" is the expected state.
                if (!device.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:        colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TranslatedText('Inactive',
                        style: TextStyle(
                            fontSize: 10, color: colors.error)),
                  ),
              ],
            ),

            // ── Overflow menu ─────────────────────────────────────────────────
            // Currently exposes only "Delete". More actions (e.g. "Reassign",
            // "View History") can be appended here later.
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deleteDevice(device);
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