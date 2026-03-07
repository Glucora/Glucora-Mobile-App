import 'package:flutter/material.dart';
import 'admin_models.dart';

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
      ).showSnackBar(const SnackBar(content: Text('No doctors available')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Doctor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A7A6E),
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
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedDoctorId = v),
              ),
              const SizedBox(height: 16),
              const Text(
                'Patient',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A7A6E),
                ),
              ),
              const SizedBox(height: 6),
              if (availablePatients.isEmpty)
                Text(
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
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedPatientId = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
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
              child: const Text(
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
        title: const Text('Remove Assignment'),
        content: Text(
          'Remove ${assignment.patientName} from ${assignment.doctorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => mockAssignments.remove(assignment));
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _doctors;
    final unassigned = _unassignedPatients();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor–Patient Assignments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A7A6E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addAssignment),
        ],
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unassigned patients banner
          if (unassigned.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F40).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF9F40).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_off,
                    color: Color(0xFFFF9F40),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${unassigned.length} Unassigned Patient${unassigned.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFFFF9F40),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unassigned.map((p) => p.name).join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
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
            return _doctorGroup(doctor, assignments);
          }),
        ],
      ),
    );
  }

  Widget _doctorGroup(
    AdminUser doctor,
    List<DoctorPatientAssignment> assignments,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  child: Text(
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
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${assignments.length} patient${assignments.length != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
              child: Text(
                'No patients assigned',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
                  child: Text(
                    _initials(a.patientName),
                    style: const TextStyle(
                      color: Color(0xFF5B8CF5),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(
                  a.patientName,
                  style: const TextStyle(fontSize: 13),
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
