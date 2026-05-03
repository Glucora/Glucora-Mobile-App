// lib\core\models\glucose_log.dart
// Model matches the actual glucose_readings schema
class GlucoseLog {
  final String id;
  final int patientId;
  final double value;
  final String source;
  final String trend;
  final bool isPredicted;
  final DateTime recordedAt;
  final String? notes;
  // Roaa
  final String? mealTime;

  GlucoseLog({
    required this.id,
    required this.patientId,
    required this.value,
    required this.source,
    required this.trend,
    required this.isPredicted,
    required this.recordedAt,
    this.notes,
    // Roaa
    this.mealTime,
  });

  factory GlucoseLog.fromJson(Map<String, dynamic> json) {
    return GlucoseLog(
      id: json['id'].toString(),
      patientId: json['patient_id'] as int,
      value: double.parse(json['value_mg_dl'].toString()),
      source: json['source'] ?? 'unknown',
      trend: json['trend'] ?? 'stable',
      isPredicted: json['is_predicted'] ?? false,
      // Roaa
      recordedAt: DateTime.parse(json['recorded_at']).toUtc(),
      notes: json['notes'],
      // Roaa
      mealTime: json['meal_time'],
    );
  }
}
