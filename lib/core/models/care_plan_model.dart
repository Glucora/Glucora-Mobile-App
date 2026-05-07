// lib\core\models\care_plan_model.dart
class CarePlan {
  final int targetGlucoseMin;
  final int targetGlucoseMax;
  final String insulinType;
  final List<BasalSegment> basalProgram;
  final double insulinToCarbRatio;
  final double sensitivityFactor;
  final double maxAutoBolus;
  final DateTime? nextAppointment;
  final String doctorNotes;

  CarePlan({
    this.targetGlucoseMin = 70,
    this.targetGlucoseMax = 180,
    this.insulinType = 'NovoLog (Fast-Acting)',
    List<BasalSegment>? basalProgram,
    this.insulinToCarbRatio = 12,
    this.sensitivityFactor = 45,
    this.maxAutoBolus = 4.0,
    this.nextAppointment,
    this.doctorNotes = '',
  }) : basalProgram =
           basalProgram ??
           [
             BasalSegment(startHour: 0, endHour: 6, rate: 0.85),
             BasalSegment(startHour: 6, endHour: 12, rate: 1.0),
             BasalSegment(startHour: 12, endHour: 24, rate: 0.9),
           ];
           
  factory CarePlan.fromJson(Map<String, dynamic> json) {
    return CarePlan(
      targetGlucoseMin: json['target_glucose_min'] ?? 70,
      targetGlucoseMax: json['target_glucose_max'] ?? 180,
      insulinType: json['insulin_type'] ?? 'NovoLog (Fast-Acting)',
      insulinToCarbRatio: (json['carb_ratio'] ?? 12).toDouble(),
      sensitivityFactor: (json['insulin_sensitivity_factor'] ?? 45).toDouble(),
      maxAutoBolus: (json['max_auto_dose_units'] ?? 4.0).toDouble(),
      nextAppointment: json['next_appointment'] != null
          ? DateTime.parse(json['next_appointment'])
          : null,
      doctorNotes: json['notes'] ?? '',
      basalProgram: [], // fetched separately from care_plan_basal_segments
    );
  }

  CarePlan copyWith({
    int? targetGlucoseMin,
    int? targetGlucoseMax,
    String? insulinType,
    List<BasalSegment>? basalProgram,
    double? insulinToCarbRatio,
    double? sensitivityFactor,
    double? maxAutoBolus,
    DateTime? nextAppointment,
    String? doctorNotes,
  }) {
    return CarePlan(
      targetGlucoseMin: targetGlucoseMin ?? this.targetGlucoseMin,
      targetGlucoseMax: targetGlucoseMax ?? this.targetGlucoseMax,
      insulinType: insulinType ?? this.insulinType,
      basalProgram: basalProgram ?? this.basalProgram,
      insulinToCarbRatio: insulinToCarbRatio ?? this.insulinToCarbRatio,
      sensitivityFactor: sensitivityFactor ?? this.sensitivityFactor,
      maxAutoBolus: maxAutoBolus ?? this.maxAutoBolus,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      doctorNotes: doctorNotes ?? this.doctorNotes,
    );
  }
}

class BasalSegment {
  final int startHour;
  final int endHour;
  final double rate;

  const BasalSegment({
    required this.startHour,
    required this.endHour,
    required this.rate,
  });

  BasalSegment copyWith({int? startHour, int? endHour, double? rate}) {
    return BasalSegment(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      rate: rate ?? this.rate,
    );
  }
}
