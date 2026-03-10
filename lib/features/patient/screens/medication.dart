enum MedicationType {
  tablet,
  capsule,
  injection,
  syrup,
  inhaler,
  drops,
  patch,
  other,
}

String medicationTypeLabel(MedicationType type) {
  switch (type) {
    case MedicationType.tablet:
      return 'Tablet';
    case MedicationType.capsule:
      return 'Capsule';
    case MedicationType.injection:
      return 'Injection';
    case MedicationType.syrup:
      return 'Syrup';
    case MedicationType.inhaler:
      return 'Inhaler';
    case MedicationType.drops:
      return 'Drops';
    case MedicationType.patch:
      return 'Patch';
    case MedicationType.other:
      return 'Other';
  }
}

class Medication {
  final String id;
  final String name;
  final MedicationType type;
  final String dosage;
  final String frequency; // e.g. "Once daily", "Twice daily", "As needed"

  const Medication({
    required this.id,
    required this.name,
    required this.type,
    required this.dosage,
    required this.frequency,
  });
}

// Module-level mutable list — same pattern as patientLogEntries in history_entry.dart.
// MedicationScreen reads/writes this list; Profile tab navigates to it.
final List<Medication> patientMedications = [
  Medication(
    id: '1',
    name: 'Metformin',
    type: MedicationType.tablet,
    dosage: '500 mg',
    frequency: 'Twice daily',
  ),
  Medication(
    id: '2',
    name: 'Insulin Glargine',
    type: MedicationType.injection,
    dosage: '20 units',
    frequency: 'Once daily',
  ),
];
