class PredictionModel {
  final double predictedGlucose;
  final String riskLevel;
  final String recommendation;

  PredictionModel({
    required this.predictedGlucose,
    required this.riskLevel,
    required this.recommendation,
  });
}