// lib/core/models/alert_model.dart
class AlertModel {
  final int id;
  final int patientId;
  final String patientUserId;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final double? glucoseValueAtTrigger;
  final bool isReadDoctor;
  final bool isReadGuardian;
  final bool isReadUser;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  AlertModel({
    required this.id,
    required this.patientId,
    required this.patientUserId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.glucoseValueAtTrigger,
    required this.isReadDoctor,
    required this.isReadGuardian,
    required this.isReadUser,
    required this.triggeredAt,
    this.resolvedAt,
  });

  AlertModel copyWith({
    bool? isReadDoctor,
    bool? isReadGuardian,
    bool? isReadUser,
  }) {
    return AlertModel(
      id: id,
      patientId: patientId,
      patientUserId: patientUserId,
      alertType: alertType,
      severity: severity,
      title: title,
      message: message,
      glucoseValueAtTrigger: glucoseValueAtTrigger,
      isReadDoctor: isReadDoctor ?? this.isReadDoctor,
      isReadGuardian: isReadGuardian ?? this.isReadGuardian,
      isReadUser: isReadUser ?? this.isReadUser,
      triggeredAt: triggeredAt,
      resolvedAt: resolvedAt,
    );
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'],
      patientId: json['patient_id'],
      patientUserId: json['patient_user_id'],
      alertType: json['alert_type'] ?? '',
      severity: json['severity'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      glucoseValueAtTrigger: json['glucose_value_at_trigger'] != null
          ? double.tryParse(json['glucose_value_at_trigger'].toString())
          : null,
      isReadDoctor: json['is_read_doctor'] ?? false,
      isReadGuardian: json['is_read_guardian'] ?? false,
      isReadUser: json['is_read_user'] ?? false,
      triggeredAt: DateTime.parse(json['triggered_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }
}
