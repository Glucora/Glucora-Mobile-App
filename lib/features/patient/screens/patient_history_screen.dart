import 'package:flutter/material.dart';
import 'history_entry.dart';
import 'history_detail_screen.dart';
import 'csv_export_sheet.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

// ── Graph filter enums ────────────────────────────────────────────────────

enum _GraphType { glucose, insulin, failures }

enum _GraphSpan { day, week, month }

// ── Top-level helpers ──────────────────────────────────────────────────────

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
      return 'CGM Failure';
    case HistoryEntryType.micropumpFailure:
      return 'Pump Failure';
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  String _activeFilter = 'All';
  _GraphType _graphType = _GraphType.glucose;
  _GraphSpan _graphSpan = _GraphSpan.day;

  final List<String> _filters = [
    'All',
    'CGM Reading',
    'Manual Log',
    'Insulin',
    'CGM Failure',
    'Pump Failure',
  ];

  // ── Computed ───────────────────────────────────────────────────────────

  List<HistoryEntry> get _filtered {
    if (_activeFilter == 'All') return patientLogEntries;
    const map = {
      'CGM Reading': HistoryEntryType.cgmReading,
      'Manual Log': HistoryEntryType.manualGlucoseLog,
      'Insulin': HistoryEntryType.insulinDelivery,
      'CGM Failure': HistoryEntryType.cgmDeviceFailure,
      'Pump Failure': HistoryEntryType.micropumpFailure,
    };
    return patientLogEntries
        .where((e) => e.type == map[_activeFilter])
        .toList();
  }

  int _countForType(HistoryEntryType t) =>
      patientLogEntries.where((e) => e.type == t).length;

  // ── Graph data ─────────────────────────────────────────────────────────

  (DateTime, DateTime) get _graphRange {
    final now = DateTime.now();
    switch (_graphSpan) {
      case _GraphSpan.day:
        return (now.subtract(const Duration(hours: 24)), now);
      case _GraphSpan.week:
        return (now.subtract(const Duration(days: 7)), now);
      case _GraphSpan.month:
        return (now.subtract(const Duration(days: 30)), now);
    }
  }

  List<_GlucosePoint> _glucosePoints(DateTime start, DateTime end) {
    final result = <_GlucosePoint>[];
    for (final e in patientLogEntries) {
      if (e.timestamp.isBefore(start) || e.timestamp.isAfter(end)) continue;
      if (e.glucoseValue == null) continue;
      if (e.type == HistoryEntryType.cgmReading ||
          e.type == HistoryEntryType.manualGlucoseLog) {
        result.add(
          _GlucosePoint(
            ts: e.timestamp,
            value: e.glucoseValue!,
            isManual: e.type == HistoryEntryType.manualGlucoseLog,
          ),
        );
      }
    }
    result.sort((a, b) => a.ts.compareTo(b.ts));
    return result;
  }

  _BarData _insulinBuckets(DateTime start, DateTime end) {
    final entries = patientLogEntries.where(
      (e) =>
          e.type == HistoryEntryType.insulinDelivery &&
          !e.timestamp.isBefore(start) &&
          !e.timestamp.isAfter(end) &&
          e.insulinUnits != null,
    );

    if (_graphSpan == _GraphSpan.day) {
      final values = List.filled(8, 0.0);
      for (final e in entries) {
        values[e.timestamp.hour ~/ 3] += e.insulinUnits!;
      }
      return _BarData(
        values: values,
        labels: const [
          '12AM',
          '3AM',
          '6AM',
          '9AM',
          '12PM',
          '3PM',
          '6PM',
          '9PM',
        ],
      );
    } else if (_graphSpan == _GraphSpan.week) {
      final values = List.filled(7, 0.0);
      final labels = List<String>.generate(7, (i) {
        final d = end.subtract(Duration(days: 6 - i));
        return ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][d.weekday - 1];
      });
      for (final e in entries) {
        final idx = 6 - end.difference(e.timestamp).inDays;
        if (idx >= 0 && idx < 7) values[idx] += e.insulinUnits!;
      }
      return _BarData(values: values, labels: labels);
    } else {
      final values = List.filled(30, 0.0);
      final labels = List<String>.generate(30, (i) {
        final d = end.subtract(Duration(days: 29 - i));
        return i % 6 == 0 ? '${d.month}/${d.day}' : '';
      });
      for (final e in entries) {
        final idx = 29 - end.difference(e.timestamp).inDays;
        if (idx >= 0 && idx < 30) values[idx] += e.insulinUnits!;
      }
      return _BarData(values: values, labels: labels);
    }
  }

  _FailureBarData _failureBuckets(DateTime start, DateTime end) {
    final entries = patientLogEntries.where(
      (e) =>
          (e.type == HistoryEntryType.cgmDeviceFailure ||
              e.type == HistoryEntryType.micropumpFailure) &&
          !e.timestamp.isBefore(start) &&
          !e.timestamp.isAfter(end),
    );

    if (_graphSpan == _GraphSpan.day) {
      final cgm = List.filled(8, 0);
      final pump = List.filled(8, 0);
      for (final e in entries) {
        final i = e.timestamp.hour ~/ 3;
        if (e.type == HistoryEntryType.cgmDeviceFailure) {
          cgm[i]++;
        } else {
          pump[i]++;
        }
      }
      return _FailureBarData(
        cgmCounts: cgm,
        pumpCounts: pump,
        labels: const [
          '12AM',
          '3AM',
          '6AM',
          '9AM',
          '12PM',
          '3PM',
          '6PM',
          '9PM',
        ],
      );
    } else if (_graphSpan == _GraphSpan.week) {
      final cgm = List.filled(7, 0);
      final pump = List.filled(7, 0);
      final labels = List<String>.generate(7, (i) {
        final d = end.subtract(Duration(days: 6 - i));
        return ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][d.weekday - 1];
      });
      for (final e in entries) {
        final idx = 6 - end.difference(e.timestamp).inDays;
        if (idx < 0 || idx >= 7) continue;
        if (e.type == HistoryEntryType.cgmDeviceFailure) {
          cgm[idx]++;
        } else {
          pump[idx]++;
        }
      }
      return _FailureBarData(cgmCounts: cgm, pumpCounts: pump, labels: labels);
    } else {
      final cgm = List.filled(30, 0);
      final pump = List.filled(30, 0);
      final labels = List<String>.generate(30, (i) {
        final d = end.subtract(Duration(days: 29 - i));
        return i % 6 == 0 ? '${d.month}/${d.day}' : '';
      });
      for (final e in entries) {
        final idx = 29 - end.difference(e.timestamp).inDays;
        if (idx < 0 || idx >= 30) continue;
        if (e.type == HistoryEntryType.cgmDeviceFailure) {
          cgm[idx]++;
        } else {
          pump[idx]++;
        }
      }
      return _FailureBarData(cgmCounts: cgm, pumpCounts: pump, labels: labels);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: _buildNavBar(context),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, isLandscape)),
                SliverToBoxAdapter(child: _buildGraphCard(context)),
                SliverToBoxAdapter(child: _buildSummaryCounts(context)),
                if (!isLandscape)
                  SliverToBoxAdapter(child: _buildFilterChipsScroll(context)),
                SliverToBoxAdapter(child: _buildListLabel(context, filtered.length)),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No entries for this filter.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 15),
                      ),
                    ),
                  ),
                if (filtered.isNotEmpty && !isLandscape)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _HistoryCard(entry: filtered[i]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                if (filtered.isNotEmpty && isLandscape)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 0,
                            mainAxisExtent: 120,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _HistoryCard(entry: filtered[i]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isLandscape) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLandscape ? 12 : 24, 16, 0),
      child: isLandscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildTitleBlock(context)),
                const SizedBox(width: 16),
                _buildFilterChipsInline(context),
              ],
            )
          : _buildTitleBlock(context),
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colors.textPrimary,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My History',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${patientLogEntries.length} total events recorded',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.upload_file_outlined),
          color: colors.primaryDark,
          tooltip: 'Export CSV',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const CsvExportSheet(),
          ),
        ),
      ],
    );
  }

  // ── Graph card ─────────────────────────────────────────────────────────

  Widget _buildGraphCard(BuildContext context) {
    final colors = context.colors;
    final (start, end) = _graphRange;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGraphTypeRow(context),
              const SizedBox(height: 10),
              _buildGraphSpanRow(context),
              const SizedBox(height: 14),
              SizedBox(height: 190, child: _buildChart(context, start, end)),
              const SizedBox(height: 8),
              _buildChartLegend(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraphTypeRow(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _graphTypeChip(context, _GraphType.glucose, Icons.show_chart_rounded, 'Glucose', colors.accent),
        const SizedBox(width: 8),
        _graphTypeChip(context, _GraphType.insulin, Icons.water_drop_outlined, 'Insulin', const Color(0xFF9B59B6)),
        const SizedBox(width: 8),
        _graphTypeChip(context, _GraphType.failures, Icons.warning_amber_rounded, 'Failures', colors.error),
      ],
    );
  }

  Widget _graphTypeChip(BuildContext context, _GraphType type, IconData icon, String label, Color activeColor) {
    final colors = context.colors;
    final isActive = _graphType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _graphType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? activeColor : colors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraphSpanRow(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _graphSpanChip(context, _GraphSpan.day, '24 Hours', colors.primaryDark),
        const SizedBox(width: 8),
        _graphSpanChip(context, _GraphSpan.week, '7 Days', colors.primaryDark),
        const SizedBox(width: 8),
        _graphSpanChip(context, _GraphSpan.month, '30 Days', colors.primaryDark),
      ],
    );
  }

  Widget _graphSpanChip(BuildContext context, _GraphSpan span, String label, Color activeColor) {
    final colors = context.colors;
    final isActive = _graphSpan == span;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _graphSpan = span),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : colors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, DateTime start, DateTime end) {
    switch (_graphType) {
      case _GraphType.glucose:
        final pts = _glucosePoints(start, end);
        if (pts.isEmpty) return _emptyChart(context, 'No glucose data in this period');
        return CustomPaint(
          painter: _GlucoseLinePainter(points: pts, start: start, end: end),
          child: const SizedBox.expand(),
        );

      case _GraphType.insulin:
        final data = _insulinBuckets(start, end);
        final hasData = data.values.any((v) => v > 0);
        if (!hasData) {
          return _emptyChart(context, 'No insulin deliveries in this period');
        }
        return CustomPaint(
          painter: _InsulinBarPainter(values: data.values, labels: data.labels),
          child: const SizedBox.expand(),
        );

      case _GraphType.failures:
        final data = _failureBuckets(start, end);
        final hasData =
            data.cgmCounts.any((v) => v > 0) ||
            data.pumpCounts.any((v) => v > 0);
        if (!hasData) return _emptyChart(context, 'No failures in this period');
        return CustomPaint(
          painter: _FailureBarPainter(
            cgmCounts: data.cgmCounts,
            pumpCounts: data.pumpCounts,
            labels: data.labels,
          ),
          child: const SizedBox.expand(),
        );
    }
  }

  Widget _emptyChart(BuildContext context, String message) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: colors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(BuildContext context) {
    final colors = context.colors;
    switch (_graphType) {
      case _GraphType.glucose:
        return Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _legendItem(colors.accent, 'CGM Reading', isLine: true),
            _legendItem(const Color(0xFF5B8CF5), 'Manual Log', isLine: false),
            _legendItem(
              colors.accent.withValues(alpha: 0.25),
              'Target 70–180 mg/dL',
              isLine: false,
              isBand: true,
            ),
          ],
        );
      case _GraphType.insulin:
        return _legendItem(
          const Color(0xFF9B59B6),
          'Insulin (U)',
          isLine: false,
        );
      case _GraphType.failures:
        return Wrap(
          spacing: 14,
          children: [
            _legendItem(colors.warning, 'CGM Failure', isLine: false),
            _legendItem(colors.error, 'Pump Failure', isLine: false),
          ],
        );
    }
  }

  Widget _legendItem(
    Color color,
    String label, {
    required bool isLine,
    bool isBand = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(width: 16, height: 2, color: color)
        else if (isBand)
          Container(
            width: 14,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: const Color(0xFF2BB6A3).withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
        ),
      ],
    );
  }

  // ── Summary counts ─────────────────────────────────────────────────────

  Widget _buildSummaryCounts(BuildContext context) {
    final colors = context.colors;
    final failureCount =
        _countForType(HistoryEntryType.cgmDeviceFailure) +
        _countForType(HistoryEntryType.micropumpFailure);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _countChip(context, 'CGM',
              _countForType(HistoryEntryType.cgmReading), colors.accent),
          const SizedBox(width: 8),
          _countChip(context, 'Manual',
              _countForType(HistoryEntryType.manualGlucoseLog), const Color(0xFF5B8CF5)),
          const SizedBox(width: 8),
          _countChip(context, 'Insulin',
              _countForType(HistoryEntryType.insulinDelivery), const Color(0xFF9B59B6)),
          const SizedBox(width: 8),
          _countChip(context, 'Failures', failureCount, colors.error),
        ],
      ),
    );
  }

  Widget _countChip(BuildContext context, String label, int count, Color color) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ────────────────────────────────────────────────────────

  Widget _buildFilterChipsScroll(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _filterChip(context, _filters[i]),
      ),
    );
  }

  Widget _buildFilterChipsInline(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _filters
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _filterChip(context, f),
            ),
          )
          .toList(),
    );
  }

  Widget _filterChip(BuildContext context, String filter) {
    final colors = context.colors;
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── List label ──────────────────────────────────────────────────────────

  Widget _buildListLabel(BuildContext context, int shownCount) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Events',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            '$shownCount shown',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav bar ──────────────────────────────────────────────────────

  Widget _buildNavBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.textSecondary.withOpacity(0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _navTile(context, Icons.home_rounded, 'Home'),
              _navTile(context, Icons.restaurant_menu_rounded, 'Calories'),
              _navTile(context, Icons.edit_rounded, 'Manual Log'),
              _navTile(context, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String label) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: colors.textSecondary),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

// ── _HistoryCard ────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _entryColor(entry.type, colors);
    final icon = _entryIcon(entry.type);
    final typeLabel = _entryTypeLabel(entry.type);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HistoryDetailScreen(entry: entry)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _typeBadge(typeLabel, color),
                          const Spacer(),
                          Text(
                            entry.timeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      _buildSummaryLine(colors, color),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSummaryLine(GlucoraColors colors, Color color) {
    switch (entry.type) {
      case HistoryEntryType.cgmReading:
      case HistoryEntryType.manualGlucoseLog:
        return Row(
          children: [
            Text(
              '${entry.glucoseValue} mg/dL',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (entry.glucoseTrend != null) ...[
              const SizedBox(width: 6),
              _trendIcon(entry.glucoseTrend!),
            ],
            if (entry.type == HistoryEntryType.manualGlucoseLog &&
                entry.logMethod != null) ...[
              const SizedBox(width: 6),
              Text(
                '• ${entry.logMethod}',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ],
        );

      case HistoryEntryType.insulinDelivery:
        return Row(
          children: [
            Expanded(
              child: Text(
                '${entry.insulinUnits} U  •  ${entry.deliveryType}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.deliverySource != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: entry.deliverySource == 'AID Auto'
                      ? const Color(0xFFE8F5E9)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.deliverySource!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: entry.deliverySource == 'AID Auto'
                        ? Colors.green
                        : colors.textSecondary,
                  ),
                ),
              ),
          ],
        );

      case HistoryEntryType.cgmDeviceFailure:
      case HistoryEntryType.micropumpFailure:
        final kind = entry.type == HistoryEntryType.cgmDeviceFailure
            ? entry.cgmFailureKind
            : entry.pumpFailureKind;
        final resolved = entry.failureResolved;
        return Row(
          children: [
            Expanded(
              child: Text(
                kind ?? 'Unknown failure',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (resolved != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: resolved
                      ? Colors.green.withValues(alpha: 0.10)
                      : colors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resolved ? 'Resolved' : 'Ongoing',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: resolved ? Colors.green : colors.error,
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  Widget _trendIcon(String trend) {
    switch (trend) {
      case 'rising_rapid':
        return const Icon(Icons.north_east, color: Colors.red, size: 16);
      case 'rising':
        return const Icon(
          Icons.trending_up,
          color: Color(0xFFFF9F40),
          size: 16,
        );
      case 'falling':
        return const Icon(
          Icons.trending_down,
          color: Color(0xFFFF9F40),
          size: 16,
        );
      case 'falling_rapid':
        return const Icon(Icons.south_east, color: Colors.red, size: 16);
      default:
        return const Icon(Icons.trending_flat, color: Colors.green, size: 16);
    }
  }
}

// ── Graph data helpers (keep existing classes) ───────────────────────────────────────────────────────

class _GlucosePoint {
  final DateTime ts;
  final int value;
  final bool isManual;

  const _GlucosePoint({
    required this.ts,
    required this.value,
    required this.isManual,
  });
}

class _BarData {
  final List<double> values;
  final List<String> labels;

  const _BarData({required this.values, required this.labels});
}

class _FailureBarData {
  final List<int> cgmCounts;
  final List<int> pumpCounts;
  final List<String> labels;

  const _FailureBarData({
    required this.cgmCounts,
    required this.pumpCounts,
    required this.labels,
  });
}

// ── Glucose Line Painter (keep as is - uses semantic colors) ─────────────────────────────────────

class _GlucoseLinePainter extends CustomPainter {
  final List<_GlucosePoint> points;
  final DateTime start;
  final DateTime end;

  static const double _padL = 38.0;
  static const double _padR = 10.0;
  static const double _padT = 10.0;
  static const double _padB = 26.0;
  static const double _minY = 40.0;
  static const double _maxY = 310.0;

  const _GlucoseLinePainter({
    required this.points,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _padL - _padR;
    final chartH = size.height - _padT - _padB;
    final totalMs = end.difference(start).inMilliseconds.toDouble();

    double xOf(DateTime ts) =>
        _padL + ts.difference(start).inMilliseconds / totalMs * chartW;

    double yOf(double val) =>
        _padT + chartH * (1 - (val - _minY) / (_maxY - _minY));

    final bandPaint = Paint()
      ..color = const Color(0xFF2BB6A3).withValues(alpha: 0.08);
    final bandTop = yOf(180);
    final bandBot = yOf(70);
    canvas.drawRect(
      Rect.fromLTRB(_padL, bandTop, _padL + chartW, bandBot),
      bandPaint,
    );

    final rangeBorderPaint = Paint()
      ..color = const Color(0xFF2BB6A3).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(_padL, bandTop),
      Offset(_padL + chartW, bandTop),
      rangeBorderPaint,
    );
    canvas.drawLine(
      Offset(_padL, bandBot),
      Offset(_padL + chartW, bandBot),
      rangeBorderPaint,
    );

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final yLabelStyle = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    for (final val in [70, 110, 150, 180, 250]) {
      final y = yOf(val.toDouble());
      if (y < _padT - 4 || y > _padT + chartH + 4) continue;
      canvas.drawLine(Offset(_padL, y), Offset(_padL + chartW, y), gridPaint);
      _drawText(
        canvas,
        '$val',
        Offset(0, y - 5),
        yLabelStyle,
        maxWidth: _padL - 3,
      );
    }

    _drawXLabels(canvas, chartW, chartH, xOf);

    final offsets = points
        .map((p) => Offset(xOf(p.ts), yOf(p.value.toDouble())))
        .toList();
    if (offsets.length == 1) {
      canvas.drawCircle(
        offsets[0],
        5,
        Paint()..color = const Color(0xFF2BB6A3),
      );
    } else {
      final linePath = Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (int i = 1; i < offsets.length; i++) {
        final prev = offsets[i - 1];
        final curr = offsets[i];
        final ctrlX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
      }

      final fillPath = Path.from(linePath)
        ..lineTo(offsets.last.dx, _padT + chartH)
        ..lineTo(offsets.first.dx, _padT + chartH)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2BB6A3).withValues(alpha: 0.30),
              const Color(0xFF2BB6A3).withValues(alpha: 0.00),
            ],
          ).createShader(Rect.fromLTWH(_padL, _padT, chartW, chartH)),
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = const Color(0xFF2BB6A3)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pos = offsets[i];
      final color = p.isManual
          ? const Color(0xFF5B8CF5)
          : const Color(0xFF2BB6A3);
      canvas.drawCircle(pos, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        pos,
        4.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(pos, 1.5, Paint()..color = color);
    }
  }

  void _drawXLabels(
    Canvas canvas,
    double chartW,
    double chartH,
    double Function(DateTime) xOf,
  ) {
    final labelY = _padT + chartH + 6;
    final style = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    final spanHours = end.difference(start).inHours;

    List<DateTime> ticks;
    String Function(DateTime) fmt;

    if (spanHours <= 26) {
      ticks = [];
      var hour = (start.hour ~/ 6 + 1) * 6;
      var t = DateTime(start.year, start.month, start.day, hour % 24);
      if (hour >= 24) t = t.add(const Duration(days: 1));
      if (t.isBefore(start)) t = t.add(const Duration(hours: 6));
      while (!t.isAfter(end)) {
        ticks.add(t);
        t = t.add(const Duration(hours: 6));
      }
      fmt = (dt) {
        final h = dt.hour;
        if (h == 0) return '12AM';
        if (h == 12) return '12PM';
        return h < 12 ? '${h}AM' : '${h - 12}PM';
      };
    } else if (spanHours <= 170) {
      ticks = List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
      fmt = (dt) => ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][dt.weekday - 1];
    } else {
      ticks = List.generate(
        5,
        (i) => start.add(Duration(days: (i * 7).toInt())),
      );
      fmt = (dt) => '${dt.month}/${dt.day}';
    }

    for (final t in ticks) {
      final x = xOf(t);
      if (x < _padL || x > _padL + chartW) continue;
      _drawText(canvas, fmt(t), Offset(x, labelY), style, centered: true);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    bool centered = false,
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final dx = centered ? offset.dx - tp.width / 2 : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_GlucoseLinePainter old) =>
      old.points != points || old.start != start || old.end != end;
}

// ── Insulin Bar Painter (keep as is) ──────────────────────────────────────────────────────

class _InsulinBarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  static const double _padL = 38.0;
  static const double _padR = 10.0;
  static const double _padT = 10.0;
  static const double _padB = 26.0;

  const _InsulinBarPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _padL - _padR;
    final chartH = size.height - _padT - _padB;
    final n = values.length;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final yMax = maxVal <= 0 ? 10.0 : (maxVal * 1.25).ceilToDouble();

    double yOf(double v) => _padT + chartH * (1 - v / yMax);

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final yStyle = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    final ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final val = yMax * i / ySteps;
      final y = yOf(val);
      canvas.drawLine(Offset(_padL, y), Offset(_padL + chartW, y), gridPaint);
      _drawText(
        canvas,
        val.toStringAsFixed(val < 10 ? 1 : 0),
        Offset(0, y - 5),
        yStyle,
        maxWidth: _padL - 3,
      );
    }

    final barColor = const Color(0xFF9B59B6);
    final barW = (chartW / n) * 0.6;
    final barSpacing = chartW / n;

    for (int i = 0; i < n; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final x = _padL + barSpacing * i + (barSpacing - barW) / 2;
      final top = yOf(v);
      final bot = yOf(0);
      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barW, bot - top),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = barColor.withValues(alpha: 0.85),
      );

      if (v > 0) {
        _drawText(
          canvas,
          v.toStringAsFixed(1),
          Offset(x + barW / 2, top - 13),
          TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: barColor),
          centered: true,
        );
      }
    }

    final xStyle = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    for (int i = 0; i < n; i++) {
      if (labels[i].isEmpty) continue;
      final x = _padL + barSpacing * i + barSpacing / 2;
      _drawText(
        canvas,
        labels[i],
        Offset(x, _padT + chartH + 6),
        xStyle,
        centered: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    bool centered = false,
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final dx = centered ? offset.dx - tp.width / 2 : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_InsulinBarPainter old) =>
      old.values != values || old.labels != labels;
}

// ── Failure Bar Painter (keep as is) ──────────────────────────────────────────────────────

class _FailureBarPainter extends CustomPainter {
  final List<int> cgmCounts;
  final List<int> pumpCounts;
  final List<String> labels;

  static const double _padL = 28.0;
  static const double _padR = 10.0;
  static const double _padT = 10.0;
  static const double _padB = 26.0;

  const _FailureBarPainter({
    required this.cgmCounts,
    required this.pumpCounts,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _padL - _padR;
    final chartH = size.height - _padT - _padB;
    final n = cgmCounts.length;

    final totals = List.generate(n, (i) => cgmCounts[i] + pumpCounts[i]);
    final maxVal = totals.reduce((a, b) => a > b ? a : b);
    final yMax = maxVal <= 0 ? 4.0 : (maxVal + 1).toDouble();

    double yOf(double v) => _padT + chartH * (1 - v / yMax);

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final yStyle = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    for (int i = 0; i <= yMax.toInt(); i++) {
      if (i > 6) break;
      final y = yOf(i.toDouble());
      canvas.drawLine(Offset(_padL, y), Offset(_padL + chartW, y), gridPaint);
      _drawText(canvas, '$i', Offset(0, y - 5), yStyle, maxWidth: _padL - 3);
    }

    const cgmColor = Color(0xFFFF9F40);
    const pumpColor = Color(0xFFFF6B6B);
    final barW = (chartW / n) * 0.6;
    final barSpacing = chartW / n;

    for (int i = 0; i < n; i++) {
      final cgm = cgmCounts[i].toDouble();
      final pump = pumpCounts[i].toDouble();
      if (cgm + pump <= 0) continue;

      final x = _padL + barSpacing * i + (barSpacing - barW) / 2;
      final botY = yOf(0);

      if (cgm > 0) {
        final top = yOf(cgm);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, top, barW, botY - top),
            topLeft: pump > 0 ? Radius.zero : const Radius.circular(4),
            topRight: pump > 0 ? Radius.zero : const Radius.circular(4),
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(4),
          ),
          Paint()..color = cgmColor.withValues(alpha: 0.85),
        );
      }

      if (pump > 0) {
        final topPump = yOf(cgm + pump);
        final botPump = cgm > 0 ? yOf(cgm) : botY;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, topPump, barW, botPump - topPump),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
            bottomLeft: cgm > 0 ? Radius.zero : const Radius.circular(4),
            bottomRight: cgm > 0 ? Radius.zero : const Radius.circular(4),
          ),
          Paint()..color = pumpColor.withValues(alpha: 0.85),
        );
      }
    }

    final xStyle = TextStyle(fontSize: 9, color: Colors.grey.shade500);
    for (int i = 0; i < n; i++) {
      if (labels[i].isEmpty) continue;
      final x = _padL + barSpacing * i + barSpacing / 2;
      _drawText(
        canvas,
        labels[i],
        Offset(x, _padT + chartH + 6),
        xStyle,
        centered: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    bool centered = false,
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final dx = centered ? offset.dx - tp.width / 2 : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_FailureBarPainter old) =>
      old.cgmCounts != cgmCounts ||
      old.pumpCounts != pumpCounts ||
      old.labels != labels;
}