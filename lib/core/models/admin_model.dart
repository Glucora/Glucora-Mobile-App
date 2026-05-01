// ─── ADMIN SHARED MODELS ─────────────────────────────────────────────────────

enum UserRole { patient, doctor, admin, guardian }

class AdminUser {
  final String id;
  String name;
  String email;
  String role;
  bool isActive;
  final DateTime createdAt;
  String? profilePictureUrl;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.profilePictureUrl,
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
      profilePictureUrl: map['profile_picture_url'] as String?,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'profile_picture_url': profilePictureUrl,
    };
  }
}

class AdminDevice {
  final String id;
  String deviceName;
  String deviceType;
  String model;
  String serialNumber;
  String assignedToUserId;
  String assignedToUserName;
  bool isActive;
  DateTime? lastSyncAt;
  String? batteryHealth;
  String? firmwareVersion;

  AdminDevice({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.model,
    required this.serialNumber,
    required this.assignedToUserId,
    required this.assignedToUserName,
    this.isActive = true,
    this.lastSyncAt,
    this.batteryHealth,
    this.firmwareVersion,
  });

  factory AdminDevice.fromMap(Map<String, dynamic> map, {String? assignedUserName}) {
    return AdminDevice(
      id: map['id'].toString(),
      deviceName: map['device_name'] as String? ?? 'Unknown Device',
      deviceType: map['device_type'] as String? ?? 'Unknown',
      model: map['model'] as String? ?? 'Unknown',
      serialNumber: map['serial_number'] as String? ?? 'N/A',
      assignedToUserId: map['patient_id'] as String? ?? '',
      assignedToUserName: assignedUserName ?? 'Unassigned',
      isActive: map['is_active'] as bool? ?? true,
      lastSyncAt: map['last_sync_at'] != null
          ? DateTime.tryParse(map['last_sync_at'] as String)
          : null,
      batteryHealth: map['battery_health'] as String?,
      firmwareVersion: map['firmware_version'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_name': deviceName,
      'device_type': deviceType,
      'model': model,
      'serial_number': serialNumber,
      'patient_id': assignedToUserId,
      'is_active': isActive,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'battery_health': batteryHealth,
      'firmware_version': firmwareVersion,
    };
  }
}

class AdminAlertRule {
  final String id;
  String name;
  String conditionType;
  double? thresholdValue;
  int? durationMinutes;
  String severity;
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

  factory AdminAlertRule.fromMap(Map<String, dynamic> map) {
    return AdminAlertRule(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      conditionType: map['condition_type'] as String? ?? '',
      thresholdValue: map['threshold_value'] as double?,
      durationMinutes: map['duration_minutes'] as int?,
      severity: map['severity'] as String? ?? 'Warning',
      isEnabled: map['is_enabled'] as bool? ?? true,
      appliesToRole: map['applies_to_role'] as String? ?? 'All Patients',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'condition_type': conditionType,
      'threshold_value': thresholdValue,
      'duration_minutes': durationMinutes,
      'severity': severity,
      'is_enabled': isEnabled,
      'applies_to_role': appliesToRole,
    };
  }
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
class AdminAlert {
  final int id;
  final int patientId;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final double? glucoseValueAtTrigger;
  final bool isReadDoctor;
  final bool isReadGuardian;
  final bool isReadUser;
  final DateTime? triggeredAt;
  final DateTime? resolvedAt;
  final String? patientUserId;

  AdminAlert({
    required this.id,
    required this.patientId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.glucoseValueAtTrigger,
    required this.isReadDoctor,
    required this.isReadGuardian,
    required this.isReadUser,
    this.triggeredAt,
    this.resolvedAt,
    this.patientUserId,
  });

  factory AdminAlert.fromMap(Map<String, dynamic> map) {
    return AdminAlert(
      id: map['id'] as int,
      patientId: map['patient_id'] as int,
      alertType: map['alert_type'] as String? ?? '',
      severity: map['severity'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      glucoseValueAtTrigger: (map['glucose_value_at_trigger'] as num?)?.toDouble(),
      isReadDoctor: map['is_read_doctor'] as bool? ?? false,
      isReadGuardian: map['is_read_guardian'] as bool? ?? false,
      isReadUser: map['is_read_user'] as bool? ?? false,
      triggeredAt: map['triggered_at'] != null
          ? DateTime.parse(map['triggered_at'] as String)
          : null,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
      patientUserId: map['patient_user_id'] as String?,
    );
  }
}

class AIPredictionStats {
  final double averageConfidenceScore;
  final double averagePredictedValue;
  final String mostCommonRiskLevel;
  final int totalPredictions;

  AIPredictionStats({
    required this.averageConfidenceScore,
    required this.averagePredictedValue,
    required this.mostCommonRiskLevel,
    required this.totalPredictions,
  });

  factory AIPredictionStats.fromJson(Map<String, dynamic> json) {
    return AIPredictionStats(
      averageConfidenceScore: (json['avg_confidence_score'] ?? 0.0).toDouble(),
      averagePredictedValue: (json['avg_predicted_value'] ?? 0.0).toDouble(),
      mostCommonRiskLevel: json['most_common_risk_level'] ?? 'N/A',
      totalPredictions: json['total_predictions'] ?? 0,
    );
  }
}
// ─── REMOVED ALL MOCK DATA ─────────────────────────────────────────────────────
// No more hardcoded lists! All data comes from Supabase now.