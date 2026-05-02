// Shared model used by CarePlanEditorScreen (doctor) and PatientCarePlanScreen (patient).

class CarePlan {
  int targetGlucoseMin;
  int targetGlucoseMax;
  String insulinType;
  List<BasalSegment> basalProgram;
  double insulinToCarbRatio;
  double sensitivityFactor;
  double maxAutoBolus;
  DateTime? nextAppointment;
  String doctorNotes;

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
}

class BasalSegment {
  int startHour;
  int endHour;
  double rate;

  BasalSegment({
    required this.startHour,
    required this.endHour,
    required this.rate,
  });
}
