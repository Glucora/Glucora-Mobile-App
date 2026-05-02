class GlucoseModel {
  final double currentGlucose;
  final List<double> history;
  final double insulinDose;
  final int batteryLevel;
  final bool isConnected;

  GlucoseModel({
    required this.currentGlucose,
    required this.history,
    required this.insulinDose,
    required this.batteryLevel,
    required this.isConnected,
  });
}