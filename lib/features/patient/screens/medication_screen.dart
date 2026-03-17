import 'package:flutter/material.dart';
import 'medication.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A7A6E),
        foregroundColor: Colors.white,
        title: const Text('Medication'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2BB6A3),
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first medication',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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

  // ── Add medication dialog ──────────────────────────
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add Medication',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        decoration: _inputDecoration('Medication Name'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onSaved: (v) => name = v!.trim(),
                      ),
                      const SizedBox(height: 14),

                      // Type dropdown
                      DropdownButtonFormField<MedicationType>(
                        initialValue: type,
                        decoration: _inputDecoration('Type'),
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

                      // Dosage
                      TextFormField(
                        decoration: _inputDecoration(
                          'Dosage (e.g. 500 mg, 20 units)',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onSaved: (v) => dosage = v!.trim(),
                      ),
                      const SizedBox(height: 14),

                      // Frequency dropdown
                      DropdownButtonFormField<String>(
                        initialValue: frequency,
                        decoration: _inputDecoration('Frequency'),
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

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2BB6A3),
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
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF4F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2BB6A3), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ── Medication card ──────────────────────────────────
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
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
              color: const Color(0xFF2BB6A3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForType(medication.type),
              color: const Color(0xFF2BB6A3),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicationTypeLabel(medication.type)}  •  ${medication.dosage}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  medication.frequency,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red[300],
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
