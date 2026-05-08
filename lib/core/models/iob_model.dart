// lib\core\models\iob_model.dart
class InsulinOnBoard {
  final String id;
  final int patientId;
  final double totalIobUnits;
  final double basalIobUnits;
  final double bolusIobUnits;
  final double diaMinutes;
  final double peakMinutes;
  final int contributingDoseCount;
  final DateTime calculatedAt;
  final DateTime expiresAt;

  const InsulinOnBoard({
    required this.id,
    required this.patientId,
    required this.totalIobUnits,
    required this.basalIobUnits,
    required this.bolusIobUnits,
    required this.diaMinutes,
    required this.peakMinutes,
    required this.contributingDoseCount,
    required this.calculatedAt,
    required this.expiresAt,
  });

  factory InsulinOnBoard.fromJson(Map<String, dynamic> json) {
    return InsulinOnBoard(
      id: json['id'].toString(),
      patientId: json['patient_id'] as int,
      totalIobUnits: (json['total_iob_units'] as num).toDouble(),
      basalIobUnits: (json['basal_iob_units'] as num).toDouble(),
      bolusIobUnits: (json['bolus_iob_units'] as num).toDouble(),
      diaMinutes: (json['dia_minutes'] as num).toDouble(),
      peakMinutes: (json['peak_minutes'] as num).toDouble(),
      contributingDoseCount: json['contributing_dose_count'] as int,
      calculatedAt: DateTime.parse(json['calculated_at']).toUtc(),
      expiresAt: DateTime.parse(json['expires_at']).toUtc(),
    );
  }

  // Is the IOB snapshot still valid or is it stale?
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  // How many minutes of active insulin remain
  double get remainingMinutes =>
      expiresAt.difference(DateTime.now().toUtc()).inMinutes.toDouble().clamp(0, diaMinutes);

  // What % of insulin has already decayed
  double get decayPercentage {
    final elapsed = DateTime.now().toUtc().difference(calculatedAt).inMinutes;
    return (elapsed / diaMinutes).clamp(0.0, 1.0);
  }

  // Guardian/doctor display helper
  String get iobLabel {
    if (totalIobUnits <= 0) return 'No active insulin';
    if (totalIobUnits < 1) return '${totalIobUnits.toStringAsFixed(2)}U (low)';
    return '${totalIobUnits.toStringAsFixed(2)}U active';
  }
}