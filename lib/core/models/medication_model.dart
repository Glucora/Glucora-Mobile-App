class MedicationReminder {
  final int id;
  final String remindAt;
  final bool isActive;

  const MedicationReminder({
    required this.id,
    required this.remindAt,
    required this.isActive,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      id: json['id'] as int,
      remindAt: json['remind_at'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  MedicationReminder copyWith({
    String? remindAt,
    bool? isActive,
  }) {
    return MedicationReminder(
      id: id,
      remindAt: remindAt ?? this.remindAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Medication {
  final int id;
  final String name;
  final String? notes;
  final int? frequency;
  final bool isActive;
  final List<MedicationReminder> reminders;

  const Medication({
    required this.id,
    required this.name,
    this.notes,
    this.frequency,
    required this.isActive,
    required this.reminders,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final reminderList = json['medication_reminder'] as List? ?? [];
    return Medication(
      id: json['id'] as int,
      name: json['name'] ?? '',
      notes: json['notes'],
      frequency: json['frequency'] as int?,
      isActive: json['is_active'] ?? true,
      reminders: reminderList
          .map((r) => MedicationReminder.fromJson(r))
          .toList(),
    );
  }

  Medication copyWith({
    String? name,
    String? notes,
    int? frequency,
    bool? isActive,
    List<MedicationReminder>? reminders,
    
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      reminders: reminders ?? this.reminders,
    );
  }
}