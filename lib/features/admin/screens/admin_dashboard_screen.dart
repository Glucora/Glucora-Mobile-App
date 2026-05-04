import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminProvider>().loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final patients =
            provider.users.where((u) => u.role == 'patient').toList();
        final doctors =
            provider.users.where((u) => u.role == 'doctor').toList();
        final guardians =
            provider.users.where((u) => u.role == 'guardian').toList();

        if (provider.isLoading) {
          return Scaffold(
            appBar: _appBar(colors, null),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.errorMessage != null) {
          return Scaffold(
            appBar: _appBar(colors, null),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TranslatedText(
                    'Failed to load data',
                    style: TextStyle(color: colors.error),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadDashboard();
                    },
                    child: const TranslatedText('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _appBar(colors, provider),
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
                            child: _statCard(context, 'Total Users',
                                '${provider.totalUsers}', Icons.people, colors.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(context, 'Patients',
                                '${patients.length}', Icons.personal_injury,
                                const Color(0xFF5B8CF5)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(context, 'Doctors',
                                '${doctors.length}', Icons.medical_services,
                                const Color(0xFF9B59B6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(context, 'Guardians',
                                '${guardians.length}', Icons.family_restroom,
                                const Color(0xFF2BB6A3)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(context, 'Devices & Alerts'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(context, 'Active Devices',
                                '${provider.activeDevices}', Icons.sensors,
                                colors.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(context, 'Inactive Devices',
                                '${provider.inactiveDevices}', Icons.sensors_off,
                                colors.error),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(context, 'Total Devices',
                                '${provider.totalDevices}', Icons.device_hub,
                                const Color(0xFF5B8CF5)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(context, 'Alerts',
                                '${provider.alerts.length}', Icons.warning_amber,
                                colors.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                          child: _statCard(context, 'Total Users',
                              '${provider.totalUsers}', Icons.people,
                              colors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(context, 'Patients',
                              '${patients.length}', Icons.personal_injury,
                              const Color(0xFF5B8CF5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(context, 'Doctors',
                              '${doctors.length}', Icons.medical_services,
                              const Color(0xFF9B59B6)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(context, 'Guardians',
                              '${guardians.length}', Icons.family_restroom,
                              const Color(0xFF2BB6A3)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'Devices'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(context, 'Active Devices',
                              '${provider.activeDevices}', Icons.sensors,
                              colors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(context, 'Inactive Devices',
                              '${provider.inactiveDevices}', Icons.sensors_off,
                              colors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _statCard(context, 'Total Devices',
                        '${provider.totalDevices}', Icons.device_hub,
                        const Color(0xFF5B8CF5)),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'Alerts'),
                    const SizedBox(height: 12),
                    _statCard(context, 'Alerts', '${provider.alerts.length}',
                        Icons.warning_amber, colors.error),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  AppBar _appBar(dynamic colors, AdminProvider? provider) {
    return AppBar(
      title: const TranslatedText(
        'Admin Dashboard',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: colors.primaryDark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (provider != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDashboard(),
            tooltip: 'Refresh',
          ),
      ],
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

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          TranslatedText(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}