import 'package:flutter/material.dart';
import '../../../core/models/admin_model.dart';
import '../../../services/admin_service.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<AdminUser> _allUsers = [];
  List<AdminDevice> _allDevices = [];
  List<AdminAlertRule> _allRules = [];
  List<DoctorPatientAssignment> _allAssignments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final results = await Future.wait([
        AdminService.getAllUsers(),
        AdminService.getAllDevices(),
        AdminService.getAllAlertRules(),
        AdminService.getAllAssignments(),
      ]);

if (mounted) {
        setState(() {
          _allUsers = results[0] as List<AdminUser>;
          _allDevices = results[1] as List<AdminDevice>;
          _allRules = results[2] as List<AdminAlertRule>;
          _allAssignments = results[3] as List<DoctorPatientAssignment>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final patients = _allUsers.where((u) => u.role == 'patient').toList();
    final doctors = _allUsers.where((u) => u.role == 'doctor').toList();
    final guardians = _allUsers.where((u) => u.role == 'guardian').toList();

    final activeDevices = _allDevices.where((d) => d.isActive).length;
    final inactiveDevices = _allDevices.where((d) => !d.isActive).length;
    final enabledRules = _allRules.where((r) => r.isEnabled).length;
    final criticalRules = _allRules.where((r) => r.severity == 'Critical').length;
    
    final unassignedPatients = patients.where(
      (p) => !_allAssignments.any((a) => a.patientId == p.id)
    ).length;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const TranslatedText(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: colors.primaryDark,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const TranslatedText(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: colors.primaryDark,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Failed to load data', style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchAllData, 
                child: const TranslatedText('Retry')
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllData,
            tooltip: 'Refresh',
          ),
        ],
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
                          '${_allUsers.length}',
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
                          'Guardians',
                          '${guardians.length}',
                          Icons.family_restroom,
                          const Color(0xFF2BB6A3),
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
                          '${_allAssignments.length}',
                          Icons.link,
                          const Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          'Unassigned Patients',
                          '$unassignedPatients',
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

          // Portrait layout
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
                        '${_allUsers.length}',
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
                        'Guardians',
                        '${guardians.length}',
                        Icons.family_restroom,
                        const Color(0xFF2BB6A3),
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
                        '${_allAssignments.length}',
                        Icons.link,
                        const Color(0xFF9B59B6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        'Unassigned',
                        '$unassignedPatients',
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
    return TranslatedText(
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
          TranslatedText(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          TranslatedText(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
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
          TranslatedText(
            'AI Model Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            'Model performance metrics, prediction accuracy, and training stats will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}