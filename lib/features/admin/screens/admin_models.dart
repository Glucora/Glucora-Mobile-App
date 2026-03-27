// ─── ADMIN SHARED MODELS ─────────────────────────────────────────────────────

enum UserRole { patient, doctor, admin, guardian }

class AdminUser {
  final String id;
  String name;
  String email;
  String role; // raw string from DB: 'patient', 'doctor', 'admin', 'guardian'
  bool isActive;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String,
      name: map['full_name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get roleLabel {
    switch (role) {
      case 'patient':
        return 'Patient';
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Admin';
      case 'guardian':
        return 'Guardian';
      default:
        return role;
    }
  }
}

class AdminDevice {
  final String id;
  String deviceName;
  String deviceType; // 'CGM' | 'Micropump'
  String model;
  String serialNumber;
  String assignedToUserId;
  String assignedToUserName;
  bool isActive;

  AdminDevice({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.model,
    required this.serialNumber,
    required this.assignedToUserId,
    required this.assignedToUserName,
    this.isActive = true,
  });
}

class AdminAlertRule {
  final String id;
  String name;
  String conditionType;
  double? thresholdValue;
  int? durationMinutes;
  String severity; // 'Critical' | 'Warning' | 'Info'
  bool isEnabled;
  String appliesToRole;

  AdminAlertRule({
    required this.id,
    required this.name,
    required this.conditionType,
    this.thresholdValue,
    this.durationMinutes,
    required this.severity,
    this.isEnabled = true,
    this.appliesToRole = 'All Patients',
  });
}

class DoctorPatientAssignment {
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;

  const DoctorPatientAssignment({
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
  });
}

// ─── MOCK DATA (devices & alerts only — users are now from Supabase) ──────────

// Kept as empty list so existing screens that haven't been migrated yet
// (dashboard, assignments, device form) still compile without errors.
// Remove this once those screens are wired to Supabase.
final List<AdminUser> mockAdminUsers = [];

final List<AdminDevice> mockAdminDevices = [
  AdminDevice(
    id: 'dev1',
    deviceName: 'Dexcom G7 #1',
    deviceType: 'CGM',
    model: 'Dexcom G7',
    serialNumber: 'DX7-2025-0001',
    assignedToUserId: 'u1',
    assignedToUserName: 'Walid Ahmed',
  ),
  AdminDevice(
    id: 'dev2',
    deviceName: 'Dexcom G7 #2',
    deviceType: 'CGM',
    model: 'Dexcom G7',
    serialNumber: 'DX7-2025-0002',
    assignedToUserId: 'u2',
    assignedToUserName: 'Qamar Salah',
  ),
  AdminDevice(
    id: 'dev3',
    deviceName: 'Omnipod 5 #1',
    deviceType: 'Micropump',
    model: 'Omnipod 5',
    serialNumber: 'OP5-2025-0001',
    assignedToUserId: 'u1',
    assignedToUserName: 'Walid Ahmed',
  ),
  AdminDevice(
    id: 'dev4',
    deviceName: 'Libre 3 #1',
    deviceType: 'CGM',
    model: 'FreeStyle Libre 3',
    serialNumber: 'FL3-2025-0001',
    assignedToUserId: 'u3',
    assignedToUserName: 'Omar Latif',
  ),
  AdminDevice(
    id: 'dev5',
    deviceName: 'Omnipod 5 #2',
    deviceType: 'Micropump',
    model: 'Omnipod 5',
    serialNumber: 'OP5-2025-0002',
    assignedToUserId: 'u4',
    assignedToUserName: 'Mayada Youssef',
  ),
  AdminDevice(
    id: 'dev6',
    deviceName: 'Dexcom G7 #3',
    deviceType: 'CGM',
    model: 'Dexcom G7',
    serialNumber: 'DX7-2025-0003',
    assignedToUserId: 'u5',
    assignedToUserName: 'Khaled Adel',
    isActive: false,
  ),
  AdminDevice(
    id: 'dev7',
    deviceName: 'Tandem t:slim X2',
    deviceType: 'Micropump',
    model: 't:slim X2',
    serialNumber: 'TX2-2025-0001',
    assignedToUserId: 'u6',
    assignedToUserName: 'Carol Amr',
  ),
];

final List<AdminAlertRule> mockAlertRules = [
  AdminAlertRule(
    id: 'ar1',
    name: 'Critical High Glucose',
    conditionType: 'Glucose High',
    thresholdValue: 250,
    severity: 'Critical',
  ),
  AdminAlertRule(
    id: 'ar2',
    name: 'Critical Low Glucose',
    conditionType: 'Glucose Low',
    thresholdValue: 54,
    severity: 'Critical',
  ),
  AdminAlertRule(
    id: 'ar3',
    name: 'High Glucose Warning',
    conditionType: 'Glucose High',
    thresholdValue: 180,
    severity: 'Warning',
  ),
  AdminAlertRule(
    id: 'ar4',
    name: 'Low Glucose Warning',
    conditionType: 'Glucose Low',
    thresholdValue: 70,
    severity: 'Warning',
  ),
  AdminAlertRule(
    id: 'ar5',
    name: 'Sensor Disconnect',
    conditionType: 'Sensor Disconnect',
    durationMinutes: 30,
    severity: 'Warning',
  ),
  AdminAlertRule(
    id: 'ar6',
    name: 'Pump Failure Alert',
    conditionType: 'Pump Failure',
    severity: 'Critical',
  ),
  AdminAlertRule(
    id: 'ar7',
    name: 'Missed Bolus Dose',
    conditionType: 'Missed Dose',
    durationMinutes: 60,
    severity: 'Warning',
  ),
  AdminAlertRule(
    id: 'ar8',
    name: 'Time Out of Range',
    conditionType: 'Time Out of Range',
    thresholdValue: 30,
    durationMinutes: 1440,
    severity: 'Info',
  ),
];

final List<DoctorPatientAssignment> mockAssignments = [
  const DoctorPatientAssignment(
    doctorId: 'd1',
    doctorName: 'Dr. Ahmed Hassan',
    patientId: 'u1',
    patientName: 'Walid Ahmed',
  ),
  const DoctorPatientAssignment(
    doctorId: 'd1',
    doctorName: 'Dr. Ahmed Hassan',
    patientId: 'u2',
    patientName: 'Qamar Salah',
  ),
  const DoctorPatientAssignment(
    doctorId: 'd2',
    doctorName: 'Dr. Sara El-Sayed',
    patientId: 'u4',
    patientName: 'Mayada Youssef',
  ),
  const DoctorPatientAssignment(
    doctorId: 'd3',
    doctorName: 'Dr. Mostafa Ali',
    patientId: 'u6',
    patientName: 'Carol Amr',
  ),
];