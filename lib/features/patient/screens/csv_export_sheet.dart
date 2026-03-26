import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'history_entry.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class CsvExportSheet extends StatefulWidget {
  const CsvExportSheet({super.key});

  @override
  State<CsvExportSheet> createState() => _CsvExportSheetState();
}

class _CsvExportSheetState extends State<CsvExportSheet> {
  String _rangePreset = '1 Week';
  DateTime? _customStart;
  DateTime? _customEnd;

  bool _includeCgm = true;
  bool _includeManual = true;
  bool _includeInsulin = true;
  bool _includeFailures = true;

  bool _isExporting = false;

  bool get _anyTypeSelected =>
      _includeCgm || _includeManual || _includeInsulin || _includeFailures;

  bool get _customRangeReady =>
      _rangePreset != 'Custom' || (_customStart != null && _customEnd != null);

  bool get _canExport => _anyTypeSelected && _customRangeReady;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final screenHeight = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Export Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colors.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRangeSection(context),
                    const SizedBox(height: 24),
                    _buildTypeSection(context),
                    const SizedBox(height: 32),
                    _buildExportButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSection(BuildContext context) {
    final colors = context.colors;
    const presets = [
      'Today',
      '3 Days',
      '1 Week',
      '2 Weeks',
      '1 Month',
      'Custom',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Icons.date_range_outlined, 'Time Range'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) => _presetChip(context, p)).toList(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _rangePreset == 'Custom'
              ? _buildCustomDateRows(context)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _presetChip(BuildContext context, String label) {
    final colors = context.colors;
    final isActive = _rangePreset == label;
    return GestureDetector(
      onTap: () => setState(() {
        _rangePreset = label;
        if (label != 'Custom') {
          _customStart = null;
          _customEnd = null;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? colors.accent : colors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateRows(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
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
          children: [
            _datePickerRow(context,
              label: 'From',
              value: _customStart,
              onPick: (d) => setState(() => _customStart = d),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _datePickerRow(context,
              label: 'To',
              value: _customEnd,
              onPick: (d) => setState(() => _customEnd = d),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerRow(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required void Function(DateTime) onPick,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: colors.accent,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, size: 18, color: colors.accent),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const Spacer(),
            Text(
              value != null
                  ? '${value.day}/${value.month}/${value.year}'
                  : 'Select date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: value != null ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, Icons.filter_list_outlined, 'Include Entry Types'),
        const SizedBox(height: 14),
        Container(
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
            children: [
              _typeRow(context,
                icon: Icons.monitor_heart_outlined,
                iconColor: colors.accent,
                label: 'CGM Readings',
                value: _includeCgm,
                onChanged: (v) => setState(() => _includeCgm = v ?? false),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _typeRow(context,
                icon: Icons.fingerprint,
                iconColor: const Color(0xFF5B8CF5),
                label: 'Manual Logs',
                value: _includeManual,
                onChanged: (v) => setState(() => _includeManual = v ?? false),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _typeRow(context,
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF9B59B6),
                label: 'Insulin Doses',
                value: _includeInsulin,
                onChanged: (v) => setState(() => _includeInsulin = v ?? false),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _typeRow(context,
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFF6B6B),
                label: 'Device Failures',
                value: _includeFailures,
                onChanged: (v) => setState(() => _includeFailures = v ?? false),
              ),
            ],
          ),
        ),
        if (!_anyTypeSelected)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Select at least one entry type to export.',
              style: TextStyle(fontSize: 12, color: colors.error),
            ),
          ),
      ],
    );
  }

  Widget _typeRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    final colors = context.colors;
    return CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      activeColor: colors.accent,
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    final colors = context.colors;
    final enabled = _canExport && !_isExporting;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? _doExport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isExporting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Export CSV',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _doExport() async {
    setState(() => _isExporting = true);

    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    switch (_rangePreset) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case '3 Days':
        startDate = now.subtract(const Duration(days: 3));
        endDate = now;
        break;
      case '1 Week':
        startDate = now.subtract(const Duration(days: 7));
        endDate = now;
        break;
      case '2 Weeks':
        startDate = now.subtract(const Duration(days: 14));
        endDate = now;
        break;
      case '1 Month':
        startDate = now.subtract(const Duration(days: 30));
        endDate = now;
        break;
      default:
        startDate = DateTime(
          _customStart!.year,
          _customStart!.month,
          _customStart!.day,
        );
        endDate = DateTime(
          _customEnd!.year,
          _customEnd!.month,
          _customEnd!.day,
          23,
          59,
          59,
        );
    }

    final allowed = <HistoryEntryType>{
      if (_includeCgm) HistoryEntryType.cgmReading,
      if (_includeManual) HistoryEntryType.manualGlucoseLog,
      if (_includeInsulin) HistoryEntryType.insulinDelivery,
      if (_includeFailures) ...[
        HistoryEntryType.cgmDeviceFailure,
        HistoryEntryType.micropumpFailure,
      ],
    };

    final entries = patientLogEntries.where((e) {
      return allowed.contains(e.type) &&
          !e.timestamp.isBefore(startDate) &&
          !e.timestamp.isAfter(endDate);
    }).toList();

    if (entries.isEmpty) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No entries match the selected range and types.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final buf = StringBuffer();
    buf.writeln(
      'Type,Timestamp,Glucose (mg/dL),Trend,'
      'CGM Device,Sensor Session,Log Method,Note,'
      'Delivery Type,Insulin Units,Delivery Source,Meal Context,'
      'Glucose at Dose (mg/dL),Failure Kind,Device/Model,'
      'Battery Level,Duration (min),Resolved',
    );
    for (final e in entries) {
      buf.writeln(_toCsvRow(e));
    }

    final dir = await getTemporaryDirectory();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}';
    final file = File('${dir.path}/glucora_export_$stamp.csv');
    await file.writeAsString(buf.toString());

    if (!mounted) return;

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/csv'),
    ], subject: 'Glucora Export – glucora_export_$stamp.csv');

    setState(() => _isExporting = false);
    if (mounted) Navigator.pop(context);
  }

  String _toCsvRow(HistoryEntry e) {
    final typeLabel = switch (e.type) {
      HistoryEntryType.cgmReading => 'CGM Reading',
      HistoryEntryType.manualGlucoseLog => 'Manual Log',
      HistoryEntryType.insulinDelivery => 'Insulin Delivery',
      HistoryEntryType.cgmDeviceFailure => 'CGM Failure',
      HistoryEntryType.micropumpFailure => 'Pump Failure',
    };
    final ts =
        '${e.timestamp.year}-${_pad(e.timestamp.month)}-${_pad(e.timestamp.day)} '
        '${_pad(e.timestamp.hour)}:${_pad(e.timestamp.minute)}';
    final failureKind = e.cgmFailureKind ?? e.pumpFailureKind ?? '';
    final deviceModel = e.cgmDevice ?? e.pumpModel ?? '';

    return [
      _q(typeLabel),
      _q(ts),
      e.glucoseValue?.toString() ?? '',
      _q(e.glucoseTrend ?? ''),
      _q(e.cgmDevice ?? ''),
      _q(e.sensorSession ?? ''),
      _q(e.logMethod ?? ''),
      _q((e.patientNote ?? '').replaceAll('"', '""')),
      _q(e.deliveryType ?? ''),
      e.insulinUnits?.toString() ?? '',
      _q(e.deliverySource ?? ''),
      _q(e.mealContext ?? ''),
      e.glucoseAtDelivery?.toString() ?? '',
      _q(failureKind),
      _q(deviceModel),
      _q(e.pumpBatteryLevel ?? ''),
      e.failureDurationMinutes?.toString() ?? '',
      e.failureResolved == null ? '' : (e.failureResolved! ? 'Yes' : 'No'),
    ].join(',');
  }

  String _q(String s) => '"$s"';
  String _pad(int n) => n.toString().padLeft(2, '0');

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}