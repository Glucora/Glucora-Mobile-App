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

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['event_type'] as String? ?? '';
    final HistoryEntryType type;
    switch (typeStr) {
      case 'cgm_reading':
        type = HistoryEntryType.cgmReading;
        break;
      case 'manual_glucose_log':
        type = HistoryEntryType.manualGlucoseLog;
        break;
      case 'insulin_delivery':
        type = HistoryEntryType.insulinDelivery;
        break;
      case 'cgm_device_failure':
        type = HistoryEntryType.cgmDeviceFailure;
        break;
      case 'micropump_failure':
        type = HistoryEntryType.micropumpFailure;
        break;
      default:
        type = HistoryEntryType.cgmReading;
    }

    final ts = DateTime.parse(json['occurred_at'] as String);
    final hour = ts.hour;
    final minute = ts.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeLabel = '$displayHour:$minute $period';

    return HistoryEntry(
      id: json['id']?.toString() ?? '',
      timeLabel: timeLabel,
      timestamp: ts,
      type: type,
      glucoseValue: json['glucose_value'] as int?,
      glucoseTrend: json['glucose_trend'] as String?,
      cgmDevice: json['cgm_device'] as String?,
      sensorSession: json['sensor_session'] as String?,
      logMethod: json['log_method'] as String?,
      patientNote: json['patient_note'] as String?,
      deliveryType: json['delivery_type'] as String?,
      insulinUnits: (json['insulin_units'] as num?)?.toDouble(),
      deliverySource: json['delivery_source'] as String?,
      mealContext: json['meal_context'] as String?,
      glucoseAtDelivery: json['glucose_at_delivery'] as int?,
      cgmFailureKind: json['cgm_failure_kind'] as String?,
      pumpFailureKind: json['pump_failure_kind'] as String?,
      pumpModel: json['pump_model'] as String?,
      pumpBatteryLevel: json['pump_battery_level'] as String?,
      failureDurationMinutes: json['failure_duration_minutes'] as int?,
      failureResolved: json['failure_resolved'] as bool?,
    );
  }
}
List<HistoryEntry> patientLogEntries = [];
