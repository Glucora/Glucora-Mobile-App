// lib/core/models/medication_model.dart

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
}