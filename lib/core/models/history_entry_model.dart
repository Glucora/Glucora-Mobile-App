enum HistoryEntryType {
  cgmReading,
  manualGlucoseLog,
  insulinDelivery,
  cgmDeviceFailure,
  micropumpFailure,
}

class HistoryEntry {
  final String id;
  final String timeLabel;
  final DateTime timestamp;

  final HistoryEntryType type;

  // CGM Reading & Manual Log
  final int? glucoseValue;
  final String?
  glucoseTrend; // 'rising_rapid'|'rising'|'stable'|'falling'|'falling_rapid'
  final String? cgmDevice;
  final String? sensorSession;

  // Manual Log only
  final String? logMethod; // 'Fingerstick' | 'Manual Entry'
  final String? patientNote;

  // Insulin Delivery
  final String? deliveryType; // 'Bolus' | 'Correction' | 'Basal Rate Change'
  final double? insulinUnits;
  final String? deliverySource; // 'AID Auto' | 'Manual' | 'Pump Program'
  final String? mealContext;
  final int? glucoseAtDelivery;

  // CGM Device Failure
  final String?
  cgmFailureKind; // 'Signal Loss'|'Calibration Error'|'Sensor Expiry'|'Sensor Disconnect'

  // Micropump Failure
  final String?
  pumpFailureKind; // 'Occlusion Detected'|'Battery Failure'|'Delivery Error'|'Pump Offline'
  final String? pumpModel;
  final String? pumpBatteryLevel;

  // Shared failure fields
  final int? failureDurationMinutes;
  final bool? failureResolved;

  const HistoryEntry({
    required this.id,
    required this.timeLabel,
    required this.timestamp,
    required this.type,
    this.glucoseValue,
    this.glucoseTrend,
    this.cgmDevice,
    this.sensorSession,
    this.logMethod,
    this.patientNote,
    this.deliveryType,
    this.insulinUnits,
    this.deliverySource,
    this.mealContext,
    this.glucoseAtDelivery,
    this.cgmFailureKind,
    this.pumpFailureKind,
    this.pumpModel,
    this.pumpBatteryLevel,
    this.failureDurationMinutes,
    this.failureResolved,
  });
}

// Helper to compute mock timestamps relative to today at runtime.
DateTime _mockTs(int daysAgo, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
}

// Module-level mutable log. ManualLogScreen prepends new entries here;
// PatientHistoryScreen reads from here at build time.
List<HistoryEntry> patientLogEntries = [
  // ── CGM Readings ───────────────────────────────────────────────────────
  HistoryEntry(
    id: 'e001',
    timeLabel: 'Today  2:32 PM',
    timestamp: _mockTs(0, 14, 32),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 128,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 6 of 10',
  ),
  HistoryEntry(
    id: 'e002',
    timeLabel: 'Today  1:57 PM',
    timestamp: _mockTs(0, 13, 57),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 145,
    glucoseTrend: 'falling',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 6 of 10',
  ),
  HistoryEntry(
    id: 'e003',
    timeLabel: 'Today  1:23 PM',
    timestamp: _mockTs(0, 13, 23),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 198,
    glucoseTrend: 'falling',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 6 of 10',
  ),
  HistoryEntry(
    id: 'e004',
    timeLabel: 'Today 12:48 PM',
    timestamp: _mockTs(0, 12, 48),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 212,
    glucoseTrend: 'rising',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 6 of 10',
  ),
  HistoryEntry(
    id: 'e005',
    timeLabel: 'Today  9:15 AM',
    timestamp: _mockTs(0, 9, 15),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 88,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 6 of 10',
  ),
  HistoryEntry(
    id: 'e006',
    timeLabel: 'Today  7:05 AM',
    timestamp: _mockTs(0, 7, 5),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 64,
    glucoseTrend: 'falling_rapid',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 6 of 10',
  ),
  HistoryEntry(
    id: 'e007',
    timeLabel: 'Yesterday 11:45 PM',
    timestamp: _mockTs(1, 23, 45),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 115,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 5 of 10',
  ),
  // ── Manual Glucose Logs ────────────────────────────────────────────────
  HistoryEntry(
    id: 'e008',
    timeLabel: 'Today  7:02 AM',
    timestamp: _mockTs(0, 7, 2),
    type: HistoryEntryType.manualGlucoseLog,
    glucoseValue: 61,
    logMethod: 'Fingerstick',
    patientNote: 'Felt shaky, confirmed low with strip.',
  ),
  HistoryEntry(
    id: 'e009',
    timeLabel: 'Yesterday  8:30 PM',
    timestamp: _mockTs(1, 20, 30),
    type: HistoryEntryType.manualGlucoseLog,
    glucoseValue: 176,
    logMethod: 'Manual Entry',
  ),
  // ── Insulin Deliveries ─────────────────────────────────────────────────
  HistoryEntry(
    id: 'e010',
    timeLabel: 'Today  1:05 PM',
    timestamp: _mockTs(0, 13, 5),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Correction',
    insulinUnits: 1.5,
    deliverySource: 'AID Auto',
    glucoseAtDelivery: 212,
  ),
  HistoryEntry(
    id: 'e011',
    timeLabel: 'Today 12:10 PM',
    timestamp: _mockTs(0, 12, 10),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Bolus',
    insulinUnits: 5.0,
    deliverySource: 'Manual',
    mealContext: 'Lunch',
    glucoseAtDelivery: 118,
  ),
  HistoryEntry(
    id: 'e012',
    timeLabel: 'Today  8:05 AM',
    timestamp: _mockTs(0, 8, 5),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Bolus',
    insulinUnits: 4.2,
    deliverySource: 'AID Auto',
    mealContext: 'Breakfast',
    glucoseAtDelivery: 95,
  ),
  HistoryEntry(
    id: 'e013',
    timeLabel: 'Yesterday  9:00 PM',
    timestamp: _mockTs(1, 21, 0),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Basal Rate Change',
    insulinUnits: 0.85,
    deliverySource: 'Pump Program',
  ),
  // ── CGM Device Failures ────────────────────────────────────────────────
  HistoryEntry(
    id: 'e014',
    timeLabel: 'Today  6:48 AM',
    timestamp: _mockTs(0, 6, 48),
    type: HistoryEntryType.cgmDeviceFailure,
    cgmFailureKind: 'Signal Loss',
    cgmDevice: 'Dexcom G7',
    failureDurationMinutes: 14,
    failureResolved: true,
  ),
  HistoryEntry(
    id: 'e015',
    timeLabel: 'Yesterday  3:20 PM',
    timestamp: _mockTs(1, 15, 20),
    type: HistoryEntryType.cgmDeviceFailure,
    cgmFailureKind: 'Calibration Error',
    cgmDevice: 'Dexcom G7',
    failureDurationMinutes: 8,
    failureResolved: true,
  ),
  HistoryEntry(
    id: 'e016',
    timeLabel: '2 days ago  7:00 AM',
    timestamp: _mockTs(2, 7, 0),
    type: HistoryEntryType.cgmDeviceFailure,
    cgmFailureKind: 'Sensor Expiry',
    cgmDevice: 'Dexcom G7',
    failureDurationMinutes: 45,
    failureResolved: true,
  ),
  // ── Micropump Failures ─────────────────────────────────────────────────
  HistoryEntry(
    id: 'e017',
    timeLabel: 'Today  5:55 AM',
    timestamp: _mockTs(0, 5, 55),
    type: HistoryEntryType.micropumpFailure,
    pumpFailureKind: 'Pump Offline',
    pumpModel: 'Omnipod 5',
    pumpBatteryLevel: '8%',
    failureDurationMinutes: 22,
    failureResolved: true,
  ),
  HistoryEntry(
    id: 'e018',
    timeLabel: 'Yesterday  1:40 PM',
    timestamp: _mockTs(1, 13, 40),
    type: HistoryEntryType.micropumpFailure,
    pumpFailureKind: 'Occlusion Detected',
    pumpModel: 'Omnipod 5',
    failureResolved: false,
  ),
  // ── 3 days ago ─────────────────────────────────────────────────────────
  HistoryEntry(
    id: 'e019',
    timeLabel: '3 days ago  8:00 AM',
    timestamp: _mockTs(3, 8, 0),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 102,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 3 of 10',
  ),
  HistoryEntry(
    id: 'e020',
    timeLabel: '3 days ago  1:00 PM',
    timestamp: _mockTs(3, 13, 0),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 169,
    glucoseTrend: 'rising',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 3 of 10',
  ),
  HistoryEntry(
    id: 'e021',
    timeLabel: '3 days ago  7:00 PM',
    timestamp: _mockTs(3, 19, 0),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 134,
    glucoseTrend: 'falling',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 3 of 10',
  ),
  HistoryEntry(
    id: 'e022',
    timeLabel: '3 days ago 12:30 PM',
    timestamp: _mockTs(3, 12, 30),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Bolus',
    insulinUnits: 4.5,
    deliverySource: 'Manual',
    mealContext: 'Lunch',
    glucoseAtDelivery: 169,
  ),
  // ── 4 days ago ─────────────────────────────────────────────────────────
  HistoryEntry(
    id: 'e023',
    timeLabel: '4 days ago  7:30 AM',
    timestamp: _mockTs(4, 7, 30),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 78,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 2 of 10',
  ),
  HistoryEntry(
    id: 'e024',
    timeLabel: '4 days ago  2:15 PM',
    timestamp: _mockTs(4, 14, 15),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 221,
    glucoseTrend: 'rising_rapid',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 2 of 10',
  ),
  HistoryEntry(
    id: 'e025',
    timeLabel: '4 days ago  8:45 PM',
    timestamp: _mockTs(4, 20, 45),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 145,
    glucoseTrend: 'falling',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 2 of 10',
  ),
  HistoryEntry(
    id: 'e026',
    timeLabel: '4 days ago  2:00 PM',
    timestamp: _mockTs(4, 14, 0),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Correction',
    insulinUnits: 2.0,
    deliverySource: 'AID Auto',
    glucoseAtDelivery: 221,
  ),
  HistoryEntry(
    id: 'e027',
    timeLabel: '4 days ago 11:10 AM',
    timestamp: _mockTs(4, 11, 10),
    type: HistoryEntryType.cgmDeviceFailure,
    cgmFailureKind: 'Sensor Disconnect',
    cgmDevice: 'Dexcom G7',
    failureDurationMinutes: 6,
    failureResolved: true,
  ),
  // ── 5 days ago ─────────────────────────────────────────────────────────
  HistoryEntry(
    id: 'e028',
    timeLabel: '5 days ago  9:00 AM',
    timestamp: _mockTs(5, 9, 0),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 118,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 1 of 10',
  ),
  HistoryEntry(
    id: 'e029',
    timeLabel: '5 days ago  3:30 PM',
    timestamp: _mockTs(5, 15, 30),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 186,
    glucoseTrend: 'rising',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 1 of 10',
  ),
  HistoryEntry(
    id: 'e030',
    timeLabel: '5 days ago  9:15 PM',
    timestamp: _mockTs(5, 21, 15),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 97,
    glucoseTrend: 'falling',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 1 of 10',
  ),
  HistoryEntry(
    id: 'e031',
    timeLabel: '5 days ago  8:00 AM',
    timestamp: _mockTs(5, 8, 0),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Bolus',
    insulinUnits: 3.8,
    deliverySource: 'AID Auto',
    mealContext: 'Breakfast',
    glucoseAtDelivery: 118,
  ),
  HistoryEntry(
    id: 'e032',
    timeLabel: '5 days ago  6:50 PM',
    timestamp: _mockTs(5, 18, 50),
    type: HistoryEntryType.micropumpFailure,
    pumpFailureKind: 'Battery Failure',
    pumpModel: 'Omnipod 5',
    pumpBatteryLevel: '3%',
    failureDurationMinutes: 30,
    failureResolved: true,
  ),
  // ── 6 days ago ─────────────────────────────────────────────────────────
  HistoryEntry(
    id: 'e033',
    timeLabel: '6 days ago  8:20 AM',
    timestamp: _mockTs(6, 8, 20),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 93,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 0 of 10',
  ),
  HistoryEntry(
    id: 'e034',
    timeLabel: '6 days ago  1:45 PM',
    timestamp: _mockTs(6, 13, 45),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 158,
    glucoseTrend: 'rising',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 0 of 10',
  ),
  HistoryEntry(
    id: 'e035',
    timeLabel: '6 days ago  7:00 PM',
    timestamp: _mockTs(6, 19, 0),
    type: HistoryEntryType.cgmReading,
    glucoseValue: 122,
    glucoseTrend: 'stable',
    cgmDevice: 'Dexcom G7',
    sensorSession: 'Day 0 of 10',
  ),
  HistoryEntry(
    id: 'e036',
    timeLabel: '6 days ago 12:50 PM',
    timestamp: _mockTs(6, 12, 50),
    type: HistoryEntryType.insulinDelivery,
    deliveryType: 'Bolus',
    insulinUnits: 5.5,
    deliverySource: 'Manual',
    mealContext: 'Lunch',
    glucoseAtDelivery: 158,
  ),
];
