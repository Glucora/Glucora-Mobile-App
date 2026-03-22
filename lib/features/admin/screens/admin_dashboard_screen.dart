import 'package:flutter/material.dart';
import 'admin_models.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: colors.background,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'System Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          'Total Users',
                          '${mockAdminUsers.length}',
                          Icons.people,
                          colors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Patients',
                          '${patients.length}',
                          Icons.personal_injury,
                          const Color(0xFF5B8CF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Doctors',
                          '${doctors.length}',
                          Icons.medical_services,
                          const Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Admins',
                          '${admins.length}',
                          Icons.admin_panel_settings,
                          const Color(0xFFFF9F40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'Devices & Alerts'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          'Active Devices',
                          '$activeDevices',
                          Icons.sensors,
                          colors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Inactive Devices',
                          '$inactiveDevices',
                          Icons.sensors_off,
                          colors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Alert Rules',
                          '$enabledRules enabled',
                          Icons.rule,
                          const Color(0xFF5B8CF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Critical Rules',
                          '$criticalRules',
                          Icons.warning_amber,
                          colors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'Assignments'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          'Total Assignments',
                          '${mockAssignments.length}',
                          Icons.link,
                          const Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Unassigned Patients',
                          '${patients.where((p) => !mockAssignments.any((a) => a.patientId == p.id)).length}',
                          Icons.person_off,
                          colors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _aiModelPlaceholder(context),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'System Overview'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        'Total Users',
                        '${mockAdminUsers.length}',
                        Icons.people,
                        colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
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
                        context,
                        'Doctors',
                        '${doctors.length}',
                        Icons.medical_services,
                        const Color(0xFF9B59B6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        'Admins',
                        '${admins.length}',
                        Icons.admin_panel_settings,
                        const Color(0xFFFF9F40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Devices'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        'Active Devices',
                        '$activeDevices',
                        Icons.sensors,
                        colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        'Inactive Devices',
                        '$inactiveDevices',
                        Icons.sensors_off,
                        colors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Alert Rules'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        'Enabled Rules',
                        '$enabledRules',
                        Icons.rule,
                        const Color(0xFF5B8CF5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        'Critical Rules',
                        '$criticalRules',
                        Icons.warning_amber,
                        colors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Assignments'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        'Total Assignments',
                        '${mockAssignments.length}',
                        Icons.link,
                        const Color(0xFF9B59B6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        'Unassigned',
                        '${patients.where((p) => !mockAssignments.any((a) => a.patientId == p.id)).length}',
                        Icons.person_off,
                        colors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _aiModelPlaceholder(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.primaryDark,
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
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
          Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _aiModelPlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.3),
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
            color: colors.accent.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'AI Model Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Model performance metrics, prediction accuracy, and training stats will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}