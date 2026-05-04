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

  final int? glucoseValue;
  final String? glucoseTrend;
  final String? cgmDevice;
  final String? sensorSession;

  final String? logMethod;
  final String? patientNote;

  final String? deliveryType;
  final double? insulinUnits;
  final String? deliverySource;
  final String? mealContext;
  final int? glucoseAtDelivery;

  final String? cgmFailureKind;

  final String? pumpFailureKind;
  final String? pumpModel;
  final String? pumpBatteryLevel;

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

  HistoryEntry copyWith({
    String? timeLabel,
    HistoryEntryType? type,
    int? glucoseValue,
    String? glucoseTrend,
    String? cgmDevice,
    String? sensorSession,
    String? logMethod,
    String? patientNote,
    String? deliveryType,
    double? insulinUnits,
    String? deliverySource,
    String? mealContext,
    int? glucoseAtDelivery,
    String? cgmFailureKind,
    String? pumpFailureKind,
    String? pumpModel,
    String? pumpBatteryLevel,
    int? failureDurationMinutes,
    bool? failureResolved,
  }) {
    return HistoryEntry(
      id: id,
      timeLabel: timeLabel ?? this.timeLabel,
      timestamp: timestamp,
      type: type ?? this.type,
      glucoseValue: glucoseValue ?? this.glucoseValue,
      glucoseTrend: glucoseTrend ?? this.glucoseTrend,
      cgmDevice: cgmDevice ?? this.cgmDevice,
      sensorSession: sensorSession ?? this.sensorSession,
      logMethod: logMethod ?? this.logMethod,
      patientNote: patientNote ?? this.patientNote,
      deliveryType: deliveryType ?? this.deliveryType,
      insulinUnits: insulinUnits ?? this.insulinUnits,
      deliverySource: deliverySource ?? this.deliverySource,
      mealContext: mealContext ?? this.mealContext,
      glucoseAtDelivery: glucoseAtDelivery ?? this.glucoseAtDelivery,
      cgmFailureKind: cgmFailureKind ?? this.cgmFailureKind,
      pumpFailureKind: pumpFailureKind ?? this.pumpFailureKind,
      pumpModel: pumpModel ?? this.pumpModel,
      pumpBatteryLevel: pumpBatteryLevel ?? this.pumpBatteryLevel,
      failureDurationMinutes:
          failureDurationMinutes ?? this.failureDurationMinutes,
      failureResolved: failureResolved ?? this.failureResolved,
    );
  }
}

List<HistoryEntry> patientLogEntries = [];