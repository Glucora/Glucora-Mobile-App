/* lib\features\guardian\screens\guardian_patient_model.dart
 */// Shared model used across all guardian screens

class GuardianPatient {
  final String id;
  final int patientId;
  final String name;
  final int age;
  final String relationship;
  final int glucoseValue;
  final String glucoseTrend;
  final bool sensorConnected;
  final bool pumpActive;
  final int dosesToday;
  final bool allDosesAutomatic;
  final String lastSeenTime;
  final String phoneNumber;

  const GuardianPatient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.relationship,
    required this.glucoseValue,
    required this.glucoseTrend,
    required this.sensorConnected,
    required this.pumpActive,
    required this.dosesToday,
    required this.allDosesAutomatic,
    required this.lastSeenTime,
    required this.phoneNumber,
  });

  String get glucoseLabel {
    if (glucoseValue < 54)   return 'Very low';
    if (glucoseValue < 70)   return 'Too low';
    if (glucoseValue <= 180) return 'In range';
    if (glucoseValue <= 250) return 'A bit high';
    if (glucoseValue <= 300) return 'Too high';
    return 'Very high';
  }

  String get overallStatus {
    if (glucoseValue < 54 || glucoseValue > 300) return 'emergency';
    if (glucoseValue < 70 || glucoseValue > 180) return 'attention';
    return 'good';
  }
}