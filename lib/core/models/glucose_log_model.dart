// lib\core\models\glucose_log_model.dart
enum GlucoseTrend { risingRapid, rising, stable, falling, fallingRapid }

enum GlucoseSource { sensor, manual, predicted }

class GlucoseLog {
  final String id;
  final int patientId;
  final double value;
  final GlucoseSource source; // replaces: String source + bool isPredicted
  final GlucoseTrend trend; // replaces: String trend
  final DateTime recordedAt;
  final String? notes;
  final String? mealTime;

  const GlucoseLog({
    required this.id,
    required this.patientId,
    required this.value,
    required this.source,
    required this.trend,
    required this.recordedAt,
    this.notes,
    this.mealTime,
  });

  // Convenience getter — replaces isPredicted bool
  bool get isPredicted => source == GlucoseSource.predicted;

  factory GlucoseLog.fromJson(Map<String, dynamic> json) {
    return GlucoseLog(
      id: json['id'].toString(),
      patientId: json['patient_id'] as int,
      value: double.parse(json['value_mg_dl'].toString()),
      source: GlucoseSource.values.byName(
        (json['source'] as String? ?? 'sensor').toLowerCase(),
      ),
      trend: GlucoseTrend.values.byName(
        _normalizeTrend(json['trend'] as String? ?? 'stable'),
      ),
      recordedAt: DateTime.parse(
        json['recorded_at'].toString().endsWith('Z') ||
                json['recorded_at'].toString().contains('+')
            ? json['recorded_at']
            : '${json['recorded_at']}Z',
      ).toUtc(),
      notes: json['notes'] as String?,
      mealTime: json['meal_time'] as String?,
    );
  }

  // Handles DB strings like "rising_rapid" -> "risingRapid"
  static String _normalizeTrend(String raw) {
    final parts = raw.toLowerCase().split('_');
    if (parts.length == 1) return parts[0];
    return parts[0] +
        parts.sublist(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  GlucoseLog copyWith({
    double? value,
    GlucoseSource? source,
    GlucoseTrend? trend,
    DateTime? recordedAt,
    String? notes,
    String? mealTime,
  }) {
    return GlucoseLog(
      id: id,
      patientId: patientId,
      value: value ?? this.value,
      source: source ?? this.source,
      trend: trend ?? this.trend,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
      mealTime: mealTime ?? this.mealTime,
    );
  }
}
