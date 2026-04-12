import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'history_entry.dart';
import 'weekly_history_sheet.dart';
import '../../../core/models/weekly_report_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class WeeklyReportScreen extends StatefulWidget {
  final DateTime? weekStart;

  const WeeklyReportScreen({super.key, this.weekStart});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late WeeklyStats _stats;
  bool _exporting = false;

  final GlobalKey _trendKey = GlobalKey();
  final GlobalKey _tirKey = GlobalKey();
  final GlobalKey _glucoseBarsKey = GlobalKey();
  final GlobalKey _insulinBarsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final start = widget.weekStart ?? weekMonday(DateTime.now());
    _stats = computeWeeklyStats(start);
  }

  Future<void> _showHistory() async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WeeklyHistorySheet(),
    );
    if (result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WeeklyReportScreen(weekStart: result),
        ),
      );
    }
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final trendBytes = await _captureWidget(_trendKey);
      final tirBytes = await _captureWidget(_tirKey);
      final glucoseBarsBytes = await _captureWidget(_glucoseBarsKey);
      final insulinBarsBytes = await _captureWidget(_insulinBarsKey);

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
      );
      final stats = _stats;
      final weekLabel = formatWeekRange(stats.weekStart, stats.weekEnd);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Text(
              'Glucora Weekly Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2BB6A3'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _pdfSafe(weekLabel),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.Divider(height: 24),

            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Metric', 'Value'],
              data: _pdfStatRows(stats),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            pw.SizedBox(height: 20),

            if (trendBytes != null) ...[
              pw.Text(
                'Glucose Trend',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Image(pw.MemoryImage(trendBytes), width: 520),
              pw.SizedBox(height: 16),
            ],
            if (tirBytes != null) ...[
              pw.Text(
                'Time in Range',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Image(pw.MemoryImage(tirBytes), width: 360),
              pw.SizedBox(height: 16),
            ],
            if (glucoseBarsBytes != null) ...[
              pw.Text(
                'Daily Average Glucose',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Image(pw.MemoryImage(glucoseBarsBytes), width: 520),
              pw.SizedBox(height: 16),
            ],
            if (insulinBarsBytes != null) ...[
              pw.Text(
                'Daily Insulin Delivery (IOB proxy)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Image(pw.MemoryImage(insulinBarsBytes), width: 520),
              pw.SizedBox(height: 16),
            ],

            if (stats.notableEvents.isNotEmpty) ...[
              pw.Text(
                'Notable Events',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...stats.notableEvents.map(
                (e) => pw.Bullet(
                  text: _pdfSafe('${e.timeLabel}: ${_eventDescription(e)}'),
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ],

            pw.SizedBox(height: 24),
            pw.Text(
              'Generated by Glucora',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ],
        ),
      );

      final pdfBytes = await doc.save();
      final dateTag =
          '${stats.weekStart.year}${stats.weekStart.month.toString().padLeft(2, '0')}${stats.weekStart.day.toString().padLeft(2, '0')}';
      final name = 'glucora_weekly_$dateTag.pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/pdf'),
      ], subject: 'Glucora Weekly Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  List<List<String>> _pdfStatRows(WeeklyStats s) => [
    [
      'Avg Glucose',
      s.avgGlucose != null
          ? '${s.avgGlucose!.toStringAsFixed(1)} mg/dL'
          : 'N/A',
    ],
    ['Min Glucose', s.minGlucose != null ? '${s.minGlucose} mg/dL' : 'N/A'],
    ['Max Glucose', s.maxGlucose != null ? '${s.maxGlucose} mg/dL' : 'N/A'],
    [
      'Time in Range (70-180)',
      s.totalReadings > 0
          ? '${(s.inRangeCount / s.totalReadings * 100).toStringAsFixed(0)}%'
          : 'N/A',
    ],
    ['Very Low Readings (<54)', '${s.veryLowCount}'],
    ['Low Readings (54-70)', '${s.lowCount}'],
    ['In Range Readings (70-180)', '${s.inRangeCount}'],
    ['High Readings (180-250)', '${s.highCount}'],
    ['Very High Readings (>=250)', '${s.veryHighCount}'],
    ['Total Insulin', '${s.totalInsulin.toStringAsFixed(1)} U'],
    ['Max Single Dose', '${s.maxSingleDose.toStringAsFixed(1)} U'],
    ['CGM Failures', '${s.cgmFailureCount}'],
    ['Pump Failures', '${s.pumpFailureCount}'],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stats = _stats;
    final weekLabel = formatWeekRange(stats.weekStart, stats.weekEnd);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Report',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              weekLabel,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Previous Weeks',
            onPressed: _showHistory,
          ),
          _exporting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  tooltip: 'Export PDF',
                  onPressed: _exportPdf,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(context, 'Summary'),
            const SizedBox(height: 10),
            _buildSummaryGrid(context, stats),
            const SizedBox(height: 24),

            _sectionHeader(context, 'Glucose Trend'),
            const SizedBox(height: 6),
            _chartCard(
              context,
              child: RepaintBoundary(
                key: _trendKey,
                child: Container(
                  color: colors.surface,
                  child: SizedBox(
                    height: 210,
                    child: CustomPaint(
                      painter: _GlucoseTrendPainter(
                        entries: stats.allGlucoseEntries,
                        weekStart: stats.weekStart,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader(context, 'Time in Range'),
            const SizedBox(height: 6),
            _chartCard(
              context,
              child: RepaintBoundary(
                key: _tirKey,
                child: Container(
                  color: colors.surface,
                  height: 200,
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: CustomPaint(
                          painter: _TIRDonutPainter(stats: stats),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Flexible(flex: 3, child: _TIRLegend(context, stats)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader(context, 'Daily Average Glucose'),
            const SizedBox(height: 6),
            _chartCard(
              context,
              child: RepaintBoundary(
                key: _glucoseBarsKey,
                child: Container(
                  color: colors.surface,
                  child: SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _DailyBarPainter(
                        values: stats.dailyAvgGlucose.map((v) => v).toList(),
                        maxValue: 300,
                        unitLabel: 'mg/dL',
                        colorFn: (v) => glucoseZoneColor(v.round()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader(context, 'Daily Insulin Delivery'),
            const SizedBox(height: 4),
            Text(
              'Total units delivered per day (used as IOB proxy)',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            _chartCard(
              context,
              child: RepaintBoundary(
                key: _insulinBarsKey,
                child: Container(
                  color: colors.surface,
                  child: SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _DailyBarPainter(
                        values: stats.dailyTotalInsulin
                            .map<double?>((v) => v > 0 ? v : null)
                            .toList(),
                        maxValue:
                            stats.dailyTotalInsulin
                                .reduce((a, b) => a > b ? a : b)
                                .ceilToDouble() +
                            2,
                        unitLabel: 'U',
                        colorFn: (_) => cInsulin,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (stats.notableEvents.isNotEmpty) ...[
              _sectionHeader(context, 'Notable Events'),
              const SizedBox(height: 10),
              _buildNotableEvents(context, stats.notableEvents),
              const SizedBox(height: 16),
            ] else ...[
              _sectionHeader(context, 'Notable Events'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.accent,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notable events this week',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final colors = context.colors;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _chartCard(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, WeeklyStats stats) {
    final colors = context.colors;
    final tirPct = stats.totalReadings > 0
        ? '${(stats.inRangeCount / stats.totalReadings * 100).toStringAsFixed(0)}%'
        : '—';

    final cards = [
      _StatCard(
        label: 'Avg Glucose',
        value: stats.avgGlucose != null
            ? stats.avgGlucose!.toStringAsFixed(0)
            : '—',
        sub: 'mg/dL',
        color: stats.avgGlucose != null
            ? glucoseZoneColor(stats.avgGlucose!.round())
            : Colors.grey,
        icon: Icons.show_chart_rounded,
      ),
      _StatCard(
        label: 'Min Glucose',
        value: stats.minGlucose != null ? '${stats.minGlucose}' : '—',
        sub: 'mg/dL',
        color: stats.minGlucose != null
            ? glucoseZoneColor(stats.minGlucose!)
            : Colors.grey,
        icon: Icons.arrow_downward_rounded,
      ),
      _StatCard(
        label: 'Max Glucose',
        value: stats.maxGlucose != null ? '${stats.maxGlucose}' : '—',
        sub: 'mg/dL',
        color: stats.maxGlucose != null
            ? glucoseZoneColor(stats.maxGlucose!)
            : Colors.grey,
        icon: Icons.arrow_upward_rounded,
      ),
      _StatCard(
        label: 'Time in Range',
        value: tirPct,
        sub: '70–180 mg/dL',
        color: cZoneInRange,
        icon: Icons.donut_large_rounded,
      ),
      _StatCard(
        label: 'Total Insulin',
        value: stats.totalInsulin.toStringAsFixed(1),
        sub: 'units',
        color: cInsulin,
        icon: Icons.vaccines_rounded,
      ),
      _StatCard(
        label: 'Max Single Dose',
        value: stats.maxSingleDose.toStringAsFixed(1),
        sub: 'units',
        color: cInsulin,
        icon: Icons.water_drop_rounded,
      ),
      _StatCard(
        label: 'High Events',
        value: '${stats.highCount + stats.veryHighCount}',
        sub: '≥ 180 mg/dL',
        color: cZoneHigh,
        icon: Icons.keyboard_arrow_up_rounded,
      ),
      _StatCard(
        label: 'Low Events',
        value: '${stats.lowCount + stats.veryLowCount}',
        sub: '< 70 mg/dL',
        color: cZoneLow,
        icon: Icons.keyboard_arrow_down_rounded,
      ),
      _StatCard(
        label: 'Device Failures',
        value: '${stats.totalFailures}',
        sub: 'CGM + Pump',
        color: stats.totalFailures > 0 ? colors.error : Colors.grey,
        icon: Icons.warning_amber_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 20) / 3;
        final aspectRatio = cellWidth / 120;
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: aspectRatio.clamp(0.6, 1.2),
          children: cards,
        );
      },
    );
  }

  Widget _buildNotableEvents(BuildContext context, List<HistoryEntry> events) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++) ...[
            _EventTile(entry: events[i]),
            if (i < events.length - 1)
              Divider(height: 1, color: colors.textSecondary.withValues(alpha: 0.2)),
          ],
        ],
      ),
    );
  }
}

// ─── Keep the existing helper functions and classes below (they are correct) ───

String _eventDescription(HistoryEntry e) {
  switch (e.type) {
    case HistoryEntryType.cgmDeviceFailure:
      final dur = e.failureDurationMinutes != null
          ? ' (${e.failureDurationMinutes} min)'
          : '';
      final resolved = e.failureResolved == false
          ? ' – Unresolved'
          : ' – Resolved';
      return 'CGM ${e.cgmFailureKind ?? 'Failure'}$dur$resolved';
    case HistoryEntryType.micropumpFailure:
      final dur = e.failureDurationMinutes != null
          ? ' (${e.failureDurationMinutes} min)'
          : '';
      final resolved = e.failureResolved == false
          ? ' – Unresolved'
          : ' – Resolved';
      final model = e.pumpModel != null ? ' – ${e.pumpModel}' : '';
      return 'Pump ${e.pumpFailureKind ?? 'Failure'}$model$dur$resolved';
    default:
      return '${glucoseZoneLabel(e.glucoseValue!)}: ${e.glucoseValue} mg/dL';
  }
}

Color _eventColor(HistoryEntry e) {
  switch (e.type) {
    case HistoryEntryType.cgmDeviceFailure:
      return const Color(0xFFEF1616);
    case HistoryEntryType.micropumpFailure:
      return cZoneHigh;
    default:
      return glucoseZoneColor(e.glucoseValue!);
  }
}

IconData _eventIcon(HistoryEntry e) {
  switch (e.type) {
    case HistoryEntryType.cgmDeviceFailure:
      return Icons.sensors_off_rounded;
    case HistoryEntryType.micropumpFailure:
      return Icons.warning_amber_rounded;
    default:
      return e.glucoseValue! < kGlucoseLow
          ? Icons.keyboard_arrow_down_rounded
          : Icons.keyboard_arrow_up_rounded;
  }
}

String _pdfSafe(String s) => s
    .replaceAll('\u2013', '-')
    .replaceAll('\u2014', '-')
    .replaceAll('\u2265', '>=')
    .replaceAll('\u2264', '<=')
    .replaceAll('\u2019', "'")
    .replaceAll('\u201C', '"')
    .replaceAll('\u201D', '"');

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha:0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 16, color: color),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 9, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final HistoryEntry entry;

  const _EventTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _eventColor(entry);
    final desc = _eventDescription(entry);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_eventIcon(entry), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.timeLabel,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TIRLegend extends StatelessWidget {
  final WeeklyStats stats;
  final BuildContext context;

  const _TIRLegend(this.context, this.stats);

  @override
  Widget build(BuildContext context) {
    final colors = this.context.colors;
    final total = stats.totalReadings;
    String pct(int count) {
      if (total == 0) return '—';
      return '${(count / total * 100).toStringAsFixed(0)}%';
    }

    final items = [
      ('Very High (≥250)', cZoneVeryHigh, stats.veryHighCount),
      ('High (180–250)', cZoneHigh, stats.highCount),
      ('In Range (70–180)', cZoneInRange, stats.inRangeCount),
      ('Low (54–70)', cZoneLow, stats.lowCount),
      ('Very Low (<54)', cZoneVeryLow, stats.veryLowCount),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final (label, color, count) = item;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF444444),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  pct(count),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Keep all custom painters as they are (they use semantic glucose zone colors) ───

class _GlucoseTrendPainter extends CustomPainter {
  final List<HistoryEntry> entries;
  final DateTime weekStart;

  _GlucoseTrendPainter({required this.entries, required this.weekStart});

  static const double _yMin = 40;
  static const double _yMax = 300;
  static const double _padL = 46;
  static const double _padR = 12;
  static const double _padT = 12;
  static const double _padB = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final cW = size.width - _padL - _padR;
    final cH = size.height - _padT - _padB;

    double xOf(DateTime ts) {
      final minutes = ts
          .difference(weekStart)
          .inMinutes
          .toDouble()
          .clamp(0, 7 * 24 * 60.0);
      return _padL + (minutes / (7 * 24 * 60)) * cW;
    }

    double yOf(double glucose) {
      final t = (glucose - _yMin) / (_yMax - _yMin);
      return _padT + (1.0 - t.clamp(0.0, 1.0)) * cH;
    }

    void drawBand(double low, double high, Color color) {
      canvas.drawRect(
        Rect.fromLTRB(_padL, yOf(high), _padL + cW, yOf(low)),
        Paint()..color = color.withValues(alpha: 0.08),
      );
    }

    drawBand(_yMin, kGlucoseVeryLow.toDouble(), cZoneVeryLow);
    drawBand(kGlucoseVeryLow.toDouble(), kGlucoseLow.toDouble(), cZoneLow);
    drawBand(kGlucoseLow.toDouble(), kGlucoseHigh.toDouble(), cZoneInRange);
    drawBand(kGlucoseHigh.toDouble(), kGlucoseVeryHigh.toDouble(), cZoneHigh);
    drawBand(kGlucoseVeryHigh.toDouble(), _yMax, cZoneVeryHigh);

    canvas.drawRect(
      Rect.fromLTWH(_padL, _padT, cW, cH),
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final dashPaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    void drawDashed(double glucoseLevel, Color color) {
      final y = yOf(glucoseLevel);
      dashPaint.color = color.withValues(alpha: 0.5);
      final path = Path();
      double x = _padL;
      while (x < _padL + cW) {
        path.moveTo(x, y);
        path.lineTo(math.min(x + 5, _padL + cW), y);
        x += 9;
      }
      canvas.drawPath(path, dashPaint);
    }

    drawDashed(kGlucoseVeryLow.toDouble(), cZoneVeryLow);
    drawDashed(kGlucoseLow.toDouble(), cZoneLow);
    drawDashed(kGlucoseHigh.toDouble(), cZoneHigh);
    drawDashed(kGlucoseVeryHigh.toDouble(), cZoneVeryHigh);

    final sepPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.6;
    for (int d = 1; d < 7; d++) {
      final x = _padL + (d / 7.0) * cW;
      canvas.drawLine(Offset(x, _padT), Offset(x, _padT + cH), sepPaint);
    }

    void drawYLabel(double glucose) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${glucose.toInt()}',
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(_padL - tp.width - 4, yOf(glucose) - tp.height / 2),
      );
    }

    for (final v in [54.0, 70.0, 120.0, 180.0, 250.0]) {
      drawYLabel(v);
    }

    for (int d = 0; d < 7; d++) {
      final x = _padL + (d + 0.5) / 7.0 * cW;
      final tp = TextPainter(
        text: TextSpan(
          text: kDayLabels[d],
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, _padT + cH + 4));
    }

    if (entries.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'No glucose data this week',
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(_padL + cW / 2 - tp.width / 2, _padT + cH / 2 - tp.height / 2),
      );
      return;
    }

    final linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;
    for (final e in entries) {
      final x = xOf(e.timestamp);
      final y = yOf(e.glucoseValue!.toDouble());
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (final e in entries) {
      final x = xOf(e.timestamp);
      final y = yOf(e.glucoseValue!.toDouble());
      final color = glucoseZoneColor(e.glucoseValue!);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
      canvas.drawCircle(
        Offset(x, y),
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlucoseTrendPainter old) =>
      old.entries != entries || old.weekStart != weekStart;
}

class _TIRDonutPainter extends CustomPainter {
  final WeeklyStats stats;

  _TIRDonutPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) - 12;
    final innerR = outerR * 0.58;

    final total = stats.totalReadings;

    if (total == 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        outerR,
        Paint()..color = Colors.grey.shade200,
      );
      canvas.drawCircle(Offset(cx, cy), innerR, Paint()..color = Colors.white);
      final tp = TextPainter(
        text: TextSpan(
          text: 'No\ndata',
          style: TextStyle(fontSize: 11, color: Colors.grey[400], height: 1.3),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: innerR * 2);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      return;
    }

    final segments = [
      (stats.veryLowCount, cZoneVeryLow),
      (stats.lowCount, cZoneLow),
      (stats.inRangeCount, cZoneInRange),
      (stats.highCount, cZoneHigh),
      (stats.veryHighCount, cZoneVeryHigh),
    ];

    double startAngle = -math.pi / 2;
    for (final (count, color) in segments) {
      if (count == 0) continue;
      final sweep = (count / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
        startAngle,
        sweep,
        true,
        Paint()..color = color,
      );
      startAngle += sweep;
    }

    canvas.drawCircle(Offset(cx, cy), innerR, Paint()..color = Colors.white);

    final tirPct = (stats.inRangeCount / total * 100).toStringAsFixed(0);
    final tp1 = TextPainter(
      text: TextSpan(
        text: '$tirPct%',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(cx - tp1.width / 2, cy - tp1.height));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'TIR',
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, cy + 2));
  }

  @override
  bool shouldRepaint(covariant _TIRDonutPainter old) => old.stats != stats;
}

class _DailyBarPainter extends CustomPainter {
  final List<double?> values;
  final double maxValue;
  final String unitLabel;
  final Color Function(double) colorFn;

  _DailyBarPainter({
    required this.values,
    required this.maxValue,
    required this.unitLabel,
    required this.colorFn,
  });

  static const double _padL = 40;
  static const double _padR = 8;
  static const double _padT = 12;
  static const double _padB = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final cW = size.width - _padL - _padR;
    final cH = size.height - _padT - _padB;
    final barAreaW = cW / 7;
    final barW = barAreaW * 0.55;
    final safeMax = maxValue > 0 ? maxValue : 1;

    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 4; i++) {
      final v = safeMax * i / 4;
      final y = _padT + (1 - i / 4) * cH;
      canvas.drawLine(Offset(_padL, y), Offset(_padL + cW, y), gridPaint);

      final label = v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 8, color: Colors.grey[400]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_padL - tp.width - 3, y - tp.height / 2));
    }

    for (int i = 0; i < 7; i++) {
      final v = values[i];
      final barX = _padL + i * barAreaW + (barAreaW - barW) / 2;

      if (v != null && v > 0) {
        final barH = (v / safeMax).clamp(0.0, 1.0) * cH;
        final top = _padT + cH - barH;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(barX, top, barW, barH),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, Paint()..color = colorFn(v));

        final label = v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(barX + barW / 2 - tp.width / 2, top - tp.height - 1),
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: kDayLabels[i],
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          _padL + i * barAreaW + barAreaW / 2 - tp.width / 2,
          _padT + cH + 5,
        ),
      );
    }

    canvas.drawLine(
      Offset(_padL, _padT),
      Offset(_padL, _padT + cH),
      Paint()
        ..color = Colors.grey.shade200
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyBarPainter old) =>
      old.values != values || old.maxValue != maxValue;
}