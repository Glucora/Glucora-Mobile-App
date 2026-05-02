// history_entry.dart
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
  final String? glucoseTrend;
  final String? cgmDevice;
  final String? sensorSession;

  // Manual Log only
  final String? logMethod;
  final String? patientNote;

  // Insulin Delivery
  final String? deliveryType;
  final double? insulinUnits;
  final String? deliverySource;
  final String? mealContext;
  final int? glucoseAtDelivery;

  // CGM Device Failure
  final String? cgmFailureKind;

  // Micropump Failure
  final String? pumpFailureKind;
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

  // ✅ Map DB event_type string to enum
  static HistoryEntryType _typeFromString(String t) {
    switch (t) {
      case 'cgm_reading':        return HistoryEntryType.cgmReading;
      case 'manual_glucose_log': return HistoryEntryType.manualGlucoseLog;
      case 'insulin_delivery':   return HistoryEntryType.insulinDelivery;
      case 'cgm_device_failure': return HistoryEntryType.cgmDeviceFailure;
      case 'micropump_failure':  return HistoryEntryType.micropumpFailure;
      default:                   return HistoryEntryType.cgmReading;
    }
  }

  // ✅ Build a human-readable time label from DateTime
  static String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(entryDay).inDays;

    final hh = local.hour > 12
        ? local.hour - 12
        : local.hour == 0 ? 12 : local.hour;
    final mm = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hh:$mm $period';

    if (diff == 0) return 'Today  $timeStr';
    if (diff == 1) return 'Yesterday  $timeStr';
    return '$diff days ago  $timeStr';
  }

  // ✅ Parse from Supabase row
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final dt = DateTime.parse(json['occurred_at']);
    return HistoryEntry(
      id: json['id'].toString(),
      timestamp: dt,
      timeLabel: _timeLabel(dt),
      type: _typeFromString(json['event_type'] ?? ''),
      glucoseValue: json['glucose_value'] as int?,
      glucoseTrend: json['glucose_trend'],
      cgmDevice: json['cgm_device'],
      sensorSession: json['sensor_session'],
      logMethod: json['log_method'],
      patientNote: json['patient_note'],
      deliveryType: json['delivery_type'],
      insulinUnits: json['insulin_units'] != null
          ? double.tryParse(json['insulin_units'].toString())
          : null,
      deliverySource: json['delivery_source'],
      mealContext: json['meal_context'],
      glucoseAtDelivery: json['glucose_at_delivery'] as int?,
      cgmFailureKind: json['cgm_failure_kind'],
      pumpFailureKind: json['pump_failure_kind'],
      pumpModel: json['pump_model'],
      pumpBatteryLevel: json['pump_battery_level'],
      failureDurationMinutes: json['failure_duration_minutes'] as int?,
      failureResolved: json['failure_resolved'] as bool?,
    );
  }

  // ✅ Convert to DB insert map
  Map<String, dynamic> toJson(int patientId) {
    String eventType;
    switch (type) {
      case HistoryEntryType.cgmReading:        eventType = 'cgm_reading'; break;
      case HistoryEntryType.manualGlucoseLog:  eventType = 'manual_glucose_log'; break;
      case HistoryEntryType.insulinDelivery:   eventType = 'insulin_delivery'; break;
      case HistoryEntryType.cgmDeviceFailure:  eventType = 'cgm_device_failure'; break;
      case HistoryEntryType.micropumpFailure:  eventType = 'micropump_failure'; break;
    }
    return {
      'patient_id': patientId,
      'event_type': eventType,
      'occurred_at': timestamp.toIso8601String(),
      if (glucoseValue != null) 'glucose_value': glucoseValue,
      if (glucoseTrend != null) 'glucose_trend': glucoseTrend,
      if (cgmDevice != null) 'cgm_device': cgmDevice,
      if (sensorSession != null) 'sensor_session': sensorSession,
      if (logMethod != null) 'log_method': logMethod,
      if (patientNote != null) 'patient_note': patientNote,
      if (deliveryType != null) 'delivery_type': deliveryType,
      if (insulinUnits != null) 'insulin_units': insulinUnits,
      if (deliverySource != null) 'delivery_source': deliverySource,
      if (mealContext != null) 'meal_context': mealContext,
      if (glucoseAtDelivery != null) 'glucose_at_delivery': glucoseAtDelivery,
      if (cgmFailureKind != null) 'cgm_failure_kind': cgmFailureKind,
      if (pumpFailureKind != null) 'pump_failure_kind': pumpFailureKind,
      if (pumpModel != null) 'pump_model': pumpModel,
      if (pumpBatteryLevel != null) 'pump_battery_level': pumpBatteryLevel,
      if (failureDurationMinutes != null) 'failure_duration_minutes': failureDurationMinutes,
      if (failureResolved != null) 'failure_resolved': failureResolved,
    };
  }
}

// ✅ No more hardcoded list — this is now empty and loaded from DB
List<HistoryEntry> patientLogEntries = [];