
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
      recordedAt: DateTime.parse(json['recorded_at']),
      notes: json['notes'],
      mealTime: json['meal_time'], // ✅ NEW
    );
  }
}