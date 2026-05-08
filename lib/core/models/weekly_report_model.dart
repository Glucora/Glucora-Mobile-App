import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/models/history_entry_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Glucose zone thresholds & colors
// ─────────────────────────────────────────────────────────────────────────────

const int kGlucoseVeryLow = 54;
const int kGlucoseLow = 70;
const int kGlucoseHigh = 180;
const int kGlucoseVeryHigh = 250;

const Color cZoneVeryLow = Color(0xFFB71C1C);
const Color cZoneLow = Color(0xFFFBC02D);
const Color cZoneInRange = Color(0xFF2BB6A3);
const Color cZoneHigh = Color(0xFFFF9F40);
const Color cZoneVeryHigh = Color(0xFFD32F2F);
const Color cInsulin = Color(0xFF9B59B6);

Color glucoseZoneColor(int value) {
  if (value < kGlucoseVeryLow) return cZoneVeryLow;
  if (value < kGlucoseLow) return cZoneLow;
  if (value < kGlucoseHigh) return cZoneInRange;
  if (value < kGlucoseVeryHigh) return cZoneHigh;
  return cZoneVeryHigh;
}

String glucoseZoneLabel(int value) {
  if (value < kGlucoseVeryLow) return 'Very Low';
  if (value < kGlucoseLow) return 'Low';
  if (value < kGlucoseHigh) return 'In Range';
  if (value < kGlucoseVeryHigh) return 'High';
  return 'Very High';
}

// ─────────────────────────────────────────────────────────────────────────────
// Date helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the Monday (start of ISO calendar week) for [date].
DateTime weekMonday(DateTime date) {
  return DateTime(date.year, date.month, date.day - (date.weekday - 1));
}

/// Formats a week range, e.g. "Mar 3 – 9, 2026" or "Feb 24 – Mar 2, 2026".
String formatWeekRange(DateTime start, DateTime end) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (start.month == end.month) {
    return '${months[start.month - 1]} ${start.day} – ${end.day}, ${start.year}';
  }
  return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}, ${start.year}';
}

/// Short day label for x-axis (Mon, Tue, …).
const List<String> kDayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double? avgGlucose;
  final int? minGlucose;
  final int? maxGlucose;
  final double totalInsulin;
  final double maxSingleDose;
  final int veryLowCount;
  final int lowCount;
  final int inRangeCount;
  final int highCount;
  final int veryHighCount;
  final int cgmFailureCount;
  final int pumpFailureCount;

  /// Index 0 = Monday … 6 = Sunday. `null` means no glucose data that day.
  final List<double?> dailyAvgGlucose;

  /// Index 0 = Monday … 6 = Sunday. 0.0 means no insulin deliveries that day.
  final List<double> dailyTotalInsulin;

  /// Failures + Very Low/Very High readings, sorted by timestamp.
  final List<HistoryEntry> notableEvents;

  /// All CGM + manual glucose entries in the week (for trend chart).
  final List<HistoryEntry> allGlucoseEntries;

  const WeeklyStats({
    required this.weekStart,
    required this.weekEnd,
    this.avgGlucose,
    this.minGlucose,
    this.maxGlucose,
    required this.totalInsulin,
    required this.maxSingleDose,
    required this.veryLowCount,
    required this.lowCount,
    required this.inRangeCount,
    required this.highCount,
    required this.veryHighCount,
    required this.cgmFailureCount,
    required this.pumpFailureCount,
    required this.dailyAvgGlucose,
    required this.dailyTotalInsulin,
    required this.notableEvents,
    required this.allGlucoseEntries,
  });

  int get totalReadings =>
      veryLowCount + lowCount + inRangeCount + highCount + veryHighCount;

  int get totalFailures => cgmFailureCount + pumpFailureCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats computation
// ─────────────────────────────────────────────────────────────────────────────

/// Computes [WeeklyStats] for the calendar week starting on [weekStart] (Monday).
/// Reads from the global [patientLogEntries] list.
WeeklyStats computeWeeklyStats(DateTime weekStart) {
  final weekEnd = DateTime(
    weekStart.year,
    weekStart.month,
    weekStart.day + 6,
    23,
    59,
    59,
  );

  final weekEntries = patientLogEntries.where((e) {
    return !e.timestamp.isBefore(weekStart) && !e.timestamp.isAfter(weekEnd);
  }).toList();

  // ── Glucose entries ──────────────────────────────────────────────────────
  final glucoseEntries =
      weekEntries
          .where(
            (e) =>
                (e.type == HistoryEntryType.cgmReading ||
                    e.type == HistoryEntryType.manualGlucoseLog) &&
                e.glucoseValue != null,
          )
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  double? avgGlucose;
  int? minGlucose;
  int? maxGlucose;
  int veryLowCount = 0,
      lowCount = 0,
      inRangeCount = 0,
      highCount = 0,
      veryHighCount = 0;

  if (glucoseEntries.isNotEmpty) {
    final values = glucoseEntries.map((e) => e.glucoseValue!).toList();
    avgGlucose = values.reduce((a, b) => a + b) / values.length;
    minGlucose = values.reduce((a, b) => a < b ? a : b);
    maxGlucose = values.reduce((a, b) => a > b ? a : b);
    for (final v in values) {
      if (v < kGlucoseVeryLow) {
        veryLowCount++;
      } else if (v < kGlucoseLow) {
        lowCount++;
      } else if (v < kGlucoseHigh) {
        inRangeCount++;
      } else if (v < kGlucoseVeryHigh) {
        highCount++;
      } else {
        veryHighCount++;
      }
    }
  }

  // ── Insulin entries ───────────────────────────────────────────────────────
  final insulinEntries = weekEntries
      .where(
        (e) =>
            e.type == HistoryEntryType.insulinDelivery &&
            e.insulinUnits != null,
      )
      .toList();

  double totalInsulin = 0;
  double maxSingleDose = 0;
  for (final e in insulinEntries) {
    totalInsulin += e.insulinUnits!;
    if (e.insulinUnits! > maxSingleDose) maxSingleDose = e.insulinUnits!;
  }

  // ── Failures ─────────────────────────────────────────────────────────────
  final cgmFailures = weekEntries
      .where((e) => e.type == HistoryEntryType.cgmDeviceFailure)
      .length;
  final pumpFailures = weekEntries
      .where((e) => e.type == HistoryEntryType.micropumpFailure)
      .length;

  // ── Daily breakdown ───────────────────────────────────────────────────────
  final dailyAvgGlucose = List<double?>.filled(7, null);
  final dailyTotalInsulin = List<double>.filled(7, 0.0);

  for (int i = 0; i < 7; i++) {
    final dayStart = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + i,
    );
    final dayEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + i,
      23,
      59,
      59,
    );

    final dayGlucose = glucoseEntries
        .where(
          (e) =>
              !e.timestamp.isBefore(dayStart) && !e.timestamp.isAfter(dayEnd),
        )
        .toList();

    if (dayGlucose.isNotEmpty) {
      final vals = dayGlucose.map((e) => e.glucoseValue!).toList();
      dailyAvgGlucose[i] = vals.reduce((a, b) => a + b) / vals.length;
    }

    final dayInsulin = insulinEntries
        .where(
          (e) =>
              !e.timestamp.isBefore(dayStart) && !e.timestamp.isAfter(dayEnd),
        )
        .toList();
    dailyTotalInsulin[i] = dayInsulin.fold(
      0.0,
      (sum, e) => sum + e.insulinUnits!,
    );
  }

  // ── Notable events ────────────────────────────────────────────────────────
  final notableEvents = weekEntries.where((e) {
    if (e.type == HistoryEntryType.cgmDeviceFailure) return true;
    if (e.type == HistoryEntryType.micropumpFailure) return true;
    if (e.glucoseValue != null &&
        (e.glucoseValue! < kGlucoseVeryLow ||
            e.glucoseValue! >= kGlucoseVeryHigh)) {
      return true;
    }
    return false;
  }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  return WeeklyStats(
    weekStart: weekStart,
    weekEnd: weekEnd,
    avgGlucose: avgGlucose,
    minGlucose: minGlucose,
    maxGlucose: maxGlucose,
    totalInsulin: totalInsulin,
    maxSingleDose: maxSingleDose,
    veryLowCount: veryLowCount,
    lowCount: lowCount,
    inRangeCount: inRangeCount,
    highCount: highCount,
    veryHighCount: veryHighCount,
    cgmFailureCount: cgmFailures,
    pumpFailureCount: pumpFailures,
    dailyAvgGlucose: dailyAvgGlucose,
    dailyTotalInsulin: dailyTotalInsulin,
    notableEvents: notableEvents,
    allGlucoseEntries: glucoseEntries,
  );
}
