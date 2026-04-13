import 'package:flutter/material.dart';
import '../../../core/models/history_entry_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

class HistoryDetailScreen extends StatelessWidget {
  final HistoryEntry entry;

  const HistoryDetailScreen({super.key, required this.entry});

  Color _entryColor(HistoryEntryType type, GlucoraColors colors) {
    switch (type) {
      case HistoryEntryType.cgmReading:
        return colors.accent;
      case HistoryEntryType.manualGlucoseLog:
        return const Color(0xFF5B8CF5);
      case HistoryEntryType.insulinDelivery:
        return const Color(0xFF9B59B6);
      case HistoryEntryType.cgmDeviceFailure:
        return colors.warning;
      case HistoryEntryType.micropumpFailure:
        return colors.error;
    }
  }

  IconData _entryIcon(HistoryEntryType type) {
    switch (type) {
      case HistoryEntryType.cgmReading:
        return Icons.monitor_heart_outlined;
      case HistoryEntryType.manualGlucoseLog:
        return Icons.fingerprint;
      case HistoryEntryType.insulinDelivery:
        return Icons.water_drop_outlined;
      case HistoryEntryType.cgmDeviceFailure:
        return Icons.bluetooth_disabled_rounded;
      case HistoryEntryType.micropumpFailure:
        return Icons.warning_amber_rounded;
    }
  }

  String _entryTypeLabel(HistoryEntryType type) {
    switch (type) {
      case HistoryEntryType.cgmReading:
        return 'CGM Reading';
      case HistoryEntryType.manualGlucoseLog:
        return 'Manual Log';
      case HistoryEntryType.insulinDelivery:
        return 'Insulin Delivery';
      case HistoryEntryType.cgmDeviceFailure:
        return 'CGM Device Failure';
      case HistoryEntryType.micropumpFailure:
        return 'Micropump Failure';
    }
  }

  String _glucoseRangeLabel(int value) {
    if (value < 54) return 'Very Low';
    if (value < 70) return 'Low';
    if (value <= 180) return 'In Range';
    if (value <= 250) return 'High';
    return 'Very High';
  }

  Color _glucoseRangeColor(int value) {
    if (value < 54) return const Color(0xFFB71C1C);
    if (value < 70) return const Color(0xFFFBC02D);
    if (value <= 180) return const Color(0xFF2BB6A3);
    if (value <= 250) return const Color(0xFFFF9F40);
    return const Color(0xFFD32F2F);
  }

  String _trendLabel(String trend) {
    switch (trend) {
      case 'rising_rapid':
        return 'Rising rapidly (+3+ mg/dL·min)';
      case 'rising':
        return 'Rising (+1–3 mg/dL·min)';
      case 'falling':
        return 'Falling (−1 to −3 mg/dL·min)';
      case 'falling_rapid':
        return 'Falling rapidly (−3+ mg/dL·min)';
      default:
        return 'Stable (±1 mg/dL·min)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _entryColor(entry.type, colors);
    final icon = _entryIcon(entry.type);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, color),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(context, color, icon),
              const SizedBox(height: 24),
              ..._buildTypeSpecificSections(context),
              const SizedBox(height: 24),
              _buildTimestampSection(context),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, Color color) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _entryTypeLabel(entry.type),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(
            entry.timeLabel,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Color color, IconData icon) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          _buildHeroContent(context, color),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, Color color) {
    final colors = context.colors;
    switch (entry.type) {
      case HistoryEntryType.cgmReading:
      case HistoryEntryType.manualGlucoseLog:
        final value = entry.glucoseValue ?? 0;
        final rangeLabel = _glucoseRangeLabel(value);
        final rangeColor = _glucoseRangeColor(value);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: rangeColor,
                    height: 1.0,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 6),
                  child: Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: rangeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rangeLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: rangeColor,
                ),
              ),
            ),
          ],
        );

      case HistoryEntryType.insulinDelivery:
        return Column(
          children: [
            Text(
              '${entry.insulinUnits} U',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.deliveryType ?? 'Delivery',
              style: TextStyle(
                fontSize: 16,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case HistoryEntryType.cgmDeviceFailure:
      case HistoryEntryType.micropumpFailure:
        final resolved = entry.failureResolved ?? false;
        final kind = entry.type == HistoryEntryType.cgmDeviceFailure
            ? entry.cgmFailureKind
            : entry.pumpFailureKind;
        return Column(
          children: [
            Text(
              kind ?? 'Device Failure',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: resolved
                    ? Colors.green.withValues(alpha: 0.12)
                    : colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                resolved ? 'Resolved' : 'Ongoing',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: resolved ? Colors.green : colors.error,
                ),
              ),
            ),
          ],
        );
    }
  }

  List<Widget> _buildTypeSpecificSections(BuildContext context) {
    switch (entry.type) {
      case HistoryEntryType.cgmReading:
        return [
          _sectionCard(context, 'Reading Details', [
            _detailRow(context, 'Glucose Value', '${entry.glucoseValue} mg/dL'),
            _detailRow(context, 'Range', _glucoseRangeLabel(entry.glucoseValue ?? 0)),
            if (entry.glucoseTrend != null)
              _detailRow(context, 'Trend', _trendLabel(entry.glucoseTrend!)),
            _detailRow(context, 'Source', 'Automated CGM'),
          ]),
          const SizedBox(height: 20),
          _sectionCard(context, 'Device', [
            _detailRow(context, 'Sensor', entry.cgmDevice ?? '—'),
            _detailRow(context, 'Session', entry.sensorSession ?? '—'),
          ]),
        ];

      case HistoryEntryType.manualGlucoseLog:
        return [
          _sectionCard(context, 'Log Details', [
            _detailRow(context, 'Glucose Value', '${entry.glucoseValue} mg/dL'),
            _detailRow(context, 'Range', _glucoseRangeLabel(entry.glucoseValue ?? 0)),
            _detailRow(context, 'Method', entry.logMethod ?? 'Manual Entry'),
            if (entry.patientNote != null && entry.patientNote!.isNotEmpty)
              _detailRow(context, 'Note', entry.patientNote!),
          ]),
        ];

      case HistoryEntryType.insulinDelivery:
        return [
          _sectionCard(context, 'Dose Details', [
            _detailRow(context, 'Delivery Type', entry.deliveryType ?? '—'),
            _detailRow(context, 'Units', '${entry.insulinUnits} U'),
            _detailRow(context, 'Source', entry.deliverySource ?? '—'),
            if (entry.mealContext != null)
              _detailRow(context, 'Meal', entry.mealContext!),
          ]),
          if (entry.glucoseAtDelivery != null) ...[
            const SizedBox(height: 20),
            _sectionCard(context, 'Context at Dosing', [
              _detailRow(
                context,
                'Glucose at Dose Time',
                '${entry.glucoseAtDelivery} mg/dL',
              ),
              _detailRow(context, 'Range', _glucoseRangeLabel(entry.glucoseAtDelivery!)),
            ]),
          ],
        ];

      case HistoryEntryType.cgmDeviceFailure:
        return [
          _sectionCard(context, 'Failure Details', [
            _detailRow(context, 'Failure Type', entry.cgmFailureKind ?? '—'),
            _detailRow(context, 'Device', entry.cgmDevice ?? '—'),
            if (entry.failureDurationMinutes != null)
              _detailRow(context, 'Duration', '${entry.failureDurationMinutes} minutes'),
            _detailRow(
              context,
              'Status',
              (entry.failureResolved ?? false) ? 'Resolved' : 'Ongoing',
            ),
          ]),
        ];

      case HistoryEntryType.micropumpFailure:
        return [
          _sectionCard(context, 'Failure Details', [
            _detailRow(context, 'Failure Type', entry.pumpFailureKind ?? '—'),
            _detailRow(context, 'Pump Model', entry.pumpModel ?? '—'),
            if (entry.pumpBatteryLevel != null)
              _detailRow(context, 'Battery Level', entry.pumpBatteryLevel!),
            if (entry.failureDurationMinutes != null)
              _detailRow(context, 'Duration', '${entry.failureDurationMinutes} minutes'),
            _detailRow(
              context,
              'Status',
              (entry.failureResolved ?? false) ? 'Resolved' : 'Ongoing',
            ),
          ]),
        ];
    }
  }

  Widget _buildTimestampSection(BuildContext context) {
    return _sectionCard(context, 'Recorded At', [
      _detailRow(context, 'Date & Time', entry.timeLabel),
      _detailRow(context, 'Entry ID', '#${entry.id}'),
    ]);
  }

  Widget _sectionCard(BuildContext context, String title, List<Widget> rows) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              rows.length,
              (i) => Column(
                children: [
                  rows[i],
                  if (i < rows.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}