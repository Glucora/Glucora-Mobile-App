import 'package:flutter/material.dart';

import 'weekly_report_model.dart';

/// Modal bottom sheet listing the last 12 completed weeks.
/// Pops with the selected [DateTime] (week Monday) or nothing if dismissed.
class WeeklyHistorySheet extends StatelessWidget {
  const WeeklyHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final currentMonday = weekMonday(DateTime.now());
    // Build list of the 12 most-recently-completed weeks (oldest first in list,
    // but we display newest first).
    final weeks = List.generate(12, (i) {
      return currentMonday.subtract(Duration(days: 7 * (i + 1)));
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── drag handle ──
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // ── title ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Previous Weeks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── week list ──
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: weeks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final monday = weeks[index];
                final stats = computeWeeklyStats(monday);
                final sunday = monday.add(const Duration(days: 6));
                final label = formatWeekRange(monday, sunday);
                return _WeekTile(
                  label: label,
                  stats: stats,
                  onTap: () => Navigator.pop(context, monday),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week tile
// ─────────────────────────────────────────────────────────────────────────────

class _WeekTile extends StatelessWidget {
  final String label;
  final WeeklyStats stats;
  final VoidCallback onTap;

  const _WeekTile({
    required this.label,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avgText = stats.avgGlucose != null
        ? '${stats.avgGlucose!.toStringAsFixed(0)} mg/dL avg'
        : 'No data';
    final eventText = stats.totalFailures > 0
        ? '· ${stats.totalFailures} event${stats.totalFailures > 1 ? 's' : ''}'
        : '';
    final tirPercent = stats.totalReadings > 0
        ? (stats.inRangeCount / stats.totalReadings * 100).toStringAsFixed(0)
        : null;
    final tirText = tirPercent != null ? '· $tirPercent% TIR' : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF2BB6A3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF2BB6A3),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$avgText$tirText  $eventText'.trim(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
