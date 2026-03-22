import 'package:flutter/material.dart';
import 'medication.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Medication'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: colors.accent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: patientMedications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first medication',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: patientMedications.length,
              itemBuilder: (context, index) {
                final med = patientMedications[index];
                return _MedicationCard(
                  medication: med,
                  onDelete: () {
                    setState(() => patientMedications.removeAt(index));
                  },
                );
              },
            ),
    );
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String dosage = '';
    String frequency = 'Once daily';
    MedicationType type = MedicationType.tablet;

    const frequencies = [
      'Once daily',
      'Twice daily',
      'Three times daily',
      'Every 8 hours',
      'Every 12 hours',
      'As needed',
      'Weekly',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colors = Theme.of(ctx).extension<GlucoraColors>()!;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.textSecondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add Medication',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          decoration: _inputDecoration(ctx, 'Medication Name', colors),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                          onSaved: (v) => name = v!.trim(),
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<MedicationType>(
                          initialValue: type,
                          decoration: _inputDecoration(ctx, 'Type', colors),
                          items: MedicationType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(medicationTypeLabel(t)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setSheetState(() => type = v);
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          decoration: _inputDecoration(
                            ctx,
                            'Dosage (e.g. 500 mg, 20 units)',
                            colors,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                          onSaved: (v) => dosage = v!.trim(),
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          initialValue: frequency,
                          decoration: _inputDecoration(ctx, 'Frequency', colors),
                          items: frequencies
                              .map(
                                (f) => DropdownMenuItem(value: f, child: Text(f)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setSheetState(() => frequency = v);
                          },
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                final newMed = Medication(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  name: name,
                                  type: type,
                                  dosage: dosage,
                                  frequency: frequency,
                                );
                                setState(() {
                                  patientMedications.insert(0, newMed);
                                });
                                Navigator.pop(ctx);
                              }
                            },
                            child: const Text(
                              'Save Medication',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, GlucoraColors colors) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onDelete;

  const _MedicationCard({required this.medication, required this.onDelete});

  IconData _iconForType(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return Icons.medication_rounded;
      case MedicationType.injection:
        return Icons.vaccines_rounded;
      case MedicationType.syrup:
        return Icons.local_drink_rounded;
      case MedicationType.inhaler:
        return Icons.air_rounded;
      case MedicationType.drops:
        return Icons.water_drop_rounded;
      case MedicationType.patch:
        return Icons.healing_rounded;
      case MedicationType.other:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForType(medication.type),
              color: colors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicationTypeLabel(medication.type)}  •  ${medication.dosage}',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  medication.frequency,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: colors.error,
              size: 22,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Medication'),
                  content: Text(
                    'Remove "${medication.name}" from your medications?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}