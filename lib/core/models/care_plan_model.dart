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
  }) : basalProgram = basalProgram ?? [
          BasalSegment(startHour: 0, endHour: 6, rate: 0.85),
          BasalSegment(startHour: 6, endHour: 12, rate: 1.0),
          BasalSegment(startHour: 12, endHour: 24, rate: 0.9),
        ];

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

  BasalSegment copyWith({
    int? startHour,
    int? endHour,
    double? rate,
  }) {
    return BasalSegment(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      rate: rate ?? this.rate,
    );
  }
}