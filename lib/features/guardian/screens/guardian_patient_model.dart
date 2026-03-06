// Shared model used across all guardian screens

class GuardianPatient {
  final String id;
  final String name;
  final int age;
  final String relationship;
  final String glucoseLabel;
  final int glucoseValue;
  final String glucoseTrend;
  final String overallStatus; // 'good' | 'attention' | 'emergency'
  final bool sensorConnected;
  final bool pumpActive;
  final int dosesToday;
  final bool allDosesAutomatic;
  final String lastSeenTime;
  final String phoneNumber;

  const GuardianPatient({
    required this.id,
    required this.name,
    required this.age,
    required this.relationship,
    required this.glucoseLabel,
    required this.glucoseValue,
    required this.glucoseTrend,
    required this.overallStatus,
    required this.sensorConnected,
    required this.pumpActive,
    required this.dosesToday,
    required this.allDosesAutomatic,
    required this.lastSeenTime,
    required this.phoneNumber,
  });
}

// Central mock data — replace with API calls when backend is ready
class GuardianMockData {
  static const List<GuardianPatient> patients = [
    GuardianPatient(
      id: 'p1', name: 'Ahmed', age: 24, relationship: 'Son',
      glucoseLabel: 'In Range', glucoseValue: 118, glucoseTrend: 'stable',
      overallStatus: 'good', sensorConnected: true, pumpActive: true,
      dosesToday: 4, allDosesAutomatic: true, lastSeenTime: '5 min ago',
      phoneNumber: '+201012345678',
    ),
    GuardianPatient(
      id: 'p2', name: 'Sara', age: 17, relationship: 'Daughter',
      glucoseLabel: 'A bit high', glucoseValue: 196, glucoseTrend: 'up',
      overallStatus: 'attention', sensorConnected: true, pumpActive: true,
      dosesToday: 5, allDosesAutomatic: false, lastSeenTime: '2 min ago',
      phoneNumber: '+201098765432',
    ),
    GuardianPatient(
      id: 'p3', name: 'Grandma Fatma', age: 67, relationship: 'Grandmother',
      glucoseLabel: 'Too low', glucoseValue: 61, glucoseTrend: 'down',
      overallStatus: 'emergency', sensorConnected: true, pumpActive: false,
      dosesToday: 2, allDosesAutomatic: true, lastSeenTime: '1 min ago',
      phoneNumber: '+201011112222',
    ),
  ];
}