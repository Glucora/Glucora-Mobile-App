import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/admin_model.dart';
import '../../../providers/admin_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminAlertRulesScreen extends StatefulWidget {
  const AdminAlertRulesScreen({super.key});

  @override
  State<AdminAlertRulesScreen> createState() => _AdminAlertRulesScreenState();
}

class _AdminAlertRulesScreenState extends State<AdminAlertRulesScreen> {
  String _severityFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<AdminProvider>().loadAlerts());
  }

  List<AdminAlert> _filtered(List<AdminAlert> alerts) {
    if (_severityFilter == 'All') return alerts;
    return alerts
        .where((a) => a.severity.toLowerCase() == _severityFilter.toLowerCase())
        .toList();
  }

  Future<void> _deleteAlert(AdminAlert alert) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Delete Alert'),
        content: TranslatedText(
            'Are you sure you want to delete "${alert.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteAlert(alert.id);
              if (mounted) {
                final error = context.read<AdminProvider>().errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TranslatedText(error ?? 'Alert deleted successfully'),
                    backgroundColor: error != null ? Colors.red : Colors.green,
                  ),
                );
                if (error != null) context.read<AdminProvider>().clearError();
              }
            },
            child: const TranslatedText(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'warning':
        return const Color(0xFFFF9F40);
      default:
        return Colors.grey;
    }
  }

  IconData _alertTypeIcon(String alertType) {
    switch (alertType) {
      case 'high_glucose':
        return Icons.arrow_upward;
      case 'low_glucose':
        return Icons.arrow_downward;
      case 'sensor_disconnect':
        return Icons.sensors_off;
      case 'pump_failure':
        return Icons.warning_amber;
      case 'missed_dose':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider.alerts);

        return Scaffold(
          appBar: AppBar(
            title: const TranslatedText(
              'Alerts',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: colors.primaryDark,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadAlerts(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          backgroundColor: colors.background,
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: ['All', 'Critical', 'Warning'].map((label) {
                          final selected = _severityFilter == label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: TranslatedText(
                                label,
                                style: TextStyle(color: colors.textPrimary),
                              ),
                              selected: selected,
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
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: TranslatedText(
                                'No alerts',
                                style:
                                    TextStyle(color: colors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) =>
                                  _alertCard(context, filtered[index]),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _alertCard(BuildContext context, AdminAlert alert) {
    final colors = context.colors;
    final color = _severityColor(alert.severity);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_alertTypeIcon(alert.alertType), color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    alert.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    alert.message,
                    style:
                        TextStyle(fontSize: 11, color: colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    _formatDate(alert.triggeredAt),
                    style:
                        TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TranslatedText(
                    alert.severity,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (alert.resolvedAt != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const TranslatedText(
                      'Resolved',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deleteAlert(alert);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: TranslatedText(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}