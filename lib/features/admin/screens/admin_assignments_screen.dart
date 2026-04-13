import 'package:flutter/material.dart';
import '../../../core/models/admin_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart'; // ← Add this import

// ADDED

class AdminAssignmentsScreen extends StatefulWidget {
  const AdminAssignmentsScreen({super.key});

  @override
  State<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends State<AdminAssignmentsScreen> {
  List<AdminUser> get _doctors =>
      mockAdminUsers.where((u) => u.role == UserRole.doctor).toList();
  List<AdminUser> get _patients =>
      mockAdminUsers.where((u) => u.role == UserRole.patient).toList();

  List<DoctorPatientAssignment> _assignmentsForDoctor(String doctorId) {
    return mockAssignments.where((a) => a.doctorId == doctorId).toList();
  }

  List<AdminUser> _unassignedPatients() {
    final assignedIds = mockAssignments.map((a) => a.patientId).toSet();
    return _patients.where((p) => !assignedIds.contains(p.id)).toList();
  }

  void _addAssignment() {
    String? selectedDoctorId;
    String? selectedPatientId;

    final availablePatients = _unassignedPatients();

    if (_doctors.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: TranslatedText('No doctors available')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const TranslatedText('New Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'Doctor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ctx.colors.primaryDark, // UPDATED
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedDoctorId,
                decoration: InputDecoration(
                  hintText: 'Select doctor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _doctors
                    .map(
                      (d) => DropdownMenuItem(value: d.id, child: TranslatedText(d.name)),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedDoctorId = v),
              ),
              const SizedBox(height: 16),
              TranslatedText(
                'Patient',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ctx.colors.primaryDark, // UPDATED
                ),
              ),
              const SizedBox(height: 6),
              if (availablePatients.isEmpty)
                TranslatedText(
                  'All patients are assigned',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedPatientId,
                  decoration: InputDecoration(
                    hintText: 'Select patient',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: availablePatients
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: TranslatedText(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPatientId = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const TranslatedText('Cancel'),
            ),
            TextButton(
              onPressed: selectedDoctorId != null && selectedPatientId != null
                  ? () {
                      final doctor = _doctors.firstWhere(
                        (d) => d.id == selectedDoctorId,
                      );
                      final patient = _patients.firstWhere(
                        (p) => p.id == selectedPatientId,
                      );
                      setState(() {
                        mockAssignments.add(
                          DoctorPatientAssignment(
                            doctorId: doctor.id,
                            doctorName: doctor.name,
                            patientId: patient.id,
                            patientName: patient.name,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    }
                  : null,
              child: const TranslatedText(
                'Assign',
                style: TextStyle(color: Color(0xFF2BB6A3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeAssignment(DoctorPatientAssignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Remove Assignment'),
        content: TranslatedText(
          'Remove ${assignment.patientName} from ${assignment.doctorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => mockAssignments.remove(assignment));
              Navigator.pop(ctx);
            },
            child: const TranslatedText('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final doctors = _doctors;
    final unassigned = _unassignedPatients();

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText(
          'Doctor–Patient Assignments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addAssignment),
        ],
      ),
      backgroundColor: colors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unassigned patients banner
          if (unassigned.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off,
                    color: colors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          '${unassigned.length} Unassigned Patient${unassigned.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colors.warning,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TranslatedText(
                          unassigned.map((p) => p.name).join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Doctor groups
          ...doctors.map((doctor) {
            final assignments = _assignmentsForDoctor(doctor.id);
            return _doctorGroup(context, doctor, assignments);
          }),
        ],
      ),
    );
  }

  Widget _doctorGroup(
    BuildContext context,
    AdminUser doctor,
    List<DoctorPatientAssignment> assignments,
  ) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(
                    0xFF9B59B6,
                  ).withValues(alpha: 0.15),
                  child: TranslatedText(
                    doctor.initials,
                    style: const TextStyle(
                      color: Color(0xFF9B59B6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        doctor.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      TranslatedText(
                        '${assignments.length} patient${assignments.length != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Patient list
          if (assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: TranslatedText(
                'No patients assigned',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            )
          else
            ...assignments.map(
              (a) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(
                    0xFF5B8CF5,
                  ).withValues(alpha: 0.15),
                  child: TranslatedText(
                    _initials(a.patientName),
                    style: const TextStyle(
                      color: Color(0xFF5B8CF5),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: TranslatedText(
                  a.patientName,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => _removeAssignment(a),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}