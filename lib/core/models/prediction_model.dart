enum RiskLevel { low, moderate, high, critical }

class PredictionModel {
  final String id;
  final int patientId;
  final double predictedGlucose;
  final DateTime predictedAt;   // when the prediction is FOR
  final DateTime generatedAt;   // when AI generated it
  final RiskLevel riskLevel;
  final String recommendation;

  const PredictionModel({
    required this.id,
    required this.patientId,
    required this.predictedGlucose,
    required this.predictedAt,
    required this.generatedAt,
    required this.riskLevel,
    required this.recommendation,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'].toString(),
      patientId: json['patient_id'] as int,
      predictedGlucose: double.parse(json['predicted_glucose'].toString()),
      predictedAt: DateTime.parse(json['predicted_at']).toUtc(),
      generatedAt: DateTime.parse(json['generated_at']).toUtc(),
      riskLevel: RiskLevel.values.byName(
        (json['risk_level'] as String).toLowerCase(),
      ),
      recommendation: json['recommendation'] as String,
    );
  }

  PredictionModel copyWith({
    double? predictedGlucose,
    DateTime? predictedAt,
    DateTime? generatedAt,
    RiskLevel? riskLevel,
    String? recommendation,
  }) {
    return PredictionModel(
      id: id,
      patientId: patientId,
      predictedGlucose: predictedGlucose ?? this.predictedGlucose,
      predictedAt: predictedAt ?? this.predictedAt,
      generatedAt: generatedAt ?? this.generatedAt,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendation: recommendation ?? this.recommendation,
    );
  }
}