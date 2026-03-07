import 'package:flutter/material.dart';
import 'admin_models.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patients = mockAdminUsers
        .where((u) => u.role == UserRole.patient)
        .toList();
    final doctors = mockAdminUsers
        .where((u) => u.role == UserRole.doctor)
        .toList();
    final admins = mockAdminUsers
        .where((u) => u.role == UserRole.admin)
        .toList();
    final activeDevices = mockAdminDevices.where((d) => d.isActive).length;
    final inactiveDevices = mockAdminDevices.where((d) => !d.isActive).length;
    final enabledRules = mockAlertRules.where((r) => r.isEnabled).length;
    final criticalRules = mockAlertRules
        .where((r) => r.severity == 'Critical')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A7A6E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('System Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total Users',
                          '${mockAdminUsers.length}',
                          Icons.people,
                          const Color(0xFF2BB6A3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Patients',
                          '${patients.length}',
                          Icons.personal_injury,
                          const Color(0xFF5B8CF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Doctors',
                          '${doctors.length}',
                          Icons.medical_services,
                          const Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Admins',
                          '${admins.length}',
                          Icons.admin_panel_settings,
                          const Color(0xFFFF9F40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Devices & Alerts'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Active Devices',
                          '$activeDevices',
                          Icons.sensors,
                          const Color(0xFF2BB6A3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Inactive Devices',
                          '$inactiveDevices',
                          Icons.sensors_off,
                          const Color(0xFFD32F2F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Alert Rules',
                          '$enabledRules enabled',
                          Icons.rule,
                          const Color(0xFF5B8CF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Critical Rules',
                          '$criticalRules',
                          Icons.warning_amber,
                          const Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Assignments'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total Assignments',
                          '${mockAssignments.length}',
                          Icons.link,
                          const Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Unassigned Patients',
                          '${patients.where((p) => !mockAssignments.any((a) => a.patientId == p.id)).length}',
                          Icons.person_off,
                          const Color(0xFFFF9F40),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _aiModelPlaceholder(),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('System Overview'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Users',
                        '${mockAdminUsers.length}',
                        Icons.people,
                        const Color(0xFF2BB6A3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Patients',
                        '${patients.length}',
                        Icons.personal_injury,
                        const Color(0xFF5B8CF5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Doctors',
                        '${doctors.length}',
                        Icons.medical_services,
                        const Color(0xFF9B59B6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Admins',
                        '${admins.length}',
                        Icons.admin_panel_settings,
                        const Color(0xFFFF9F40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Devices'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Active Devices',
                        '$activeDevices',
                        Icons.sensors,
                        const Color(0xFF2BB6A3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Inactive Devices',
                        '$inactiveDevices',
                        Icons.sensors_off,
                        const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Alert Rules'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Enabled Rules',
                        '$enabledRules',
                        Icons.rule,
                        const Color(0xFF5B8CF5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Critical Rules',
                        '$criticalRules',
                        Icons.warning_amber,
                        const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Assignments'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Assignments',
                        '${mockAssignments.length}',
                        Icons.link,
                        const Color(0xFF9B59B6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Unassigned',
                        '${patients.where((p) => !mockAssignments.any((a) => a.patientId == p.id)).length}',
                        Icons.person_off,
                        const Color(0xFFFF9F40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _aiModelPlaceholder(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A7A6E),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _aiModelPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2BB6A3).withValues(alpha: 0.3),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            size: 48,
            color: const Color(0xFF2BB6A3).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'AI Model Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A7A6E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Model performance metrics, prediction accuracy, and training stats will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
