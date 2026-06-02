import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/providers/admin_riverpod_providers.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminUsersProvider.notifier).loadUsers();
      ref.read(adminDevicesProvider.notifier).loadDevices();
      ref.read(adminAlertsProvider.notifier).loadAlerts();
    });
  }

  void _reload() {
    ref.read(adminUsersProvider.notifier).loadUsers();
    ref.read(adminDevicesProvider.notifier).loadDevices();
    ref.read(adminAlertsProvider.notifier).loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dashboard = ref.watch(adminDashboardProvider);
    final users = dashboard.users;
    final devices = dashboard.devices;
    final alerts = dashboard.alerts;

    final isLoading =
        users.isLoading || devices.isLoading || alerts.isLoading;
    final error = users.error ?? devices.error ?? alerts.error;

    final patients = users.users.where((u) => u.role == 'patient').toList();
    final doctors = users.users.where((u) => u.role == 'doctor').toList();
    final guardians = users.users.where((u) => u.role == 'guardian').toList();

    if (isLoading) {
      return Scaffold(
        appBar: _appBar(colors, null),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: _appBar(colors, null),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Failed to load data',
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _reload,
                child: const TranslatedText('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _appBar(colors, _reload),
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'System Overview'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard(context, 'Total Users',
                  '${users.totalUsers}', Icons.people, colors.accent)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(context, 'Patients',
                  '${patients.length}', Icons.personal_injury,
                  const Color(0xFF5B8CF5))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard(context, 'Doctors',
                  '${doctors.length}', Icons.medical_services,
                  const Color(0xFF9B59B6))),
              const SizedBox(width: 12),
              Expanded(child: _statCard(context, 'Guardians',
                  '${guardians.length}', Icons.family_restroom,
                  const Color(0xFF2BB6A3))),
            ]),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Devices'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard(context, 'Active',
                  '${devices.activeDevices}', Icons.sensors, colors.accent)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(context, 'Inactive',
                  '${devices.inactiveDevices}', Icons.sensors_off,
                  colors.error)),
            ]),
            const SizedBox(height: 12),
            _statCard(context, 'Total Devices', '${devices.totalDevices}',
                Icons.device_hub, const Color(0xFF5B8CF5)),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Alerts'),
            const SizedBox(height: 12),
            _statCard(context, 'Alerts', '${alerts.alerts.length}',
                Icons.warning_amber, colors.error),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(dynamic colors, VoidCallback? onRefresh) {
    return AppBar(
      title: const TranslatedText('Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: colors.primaryDark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return TranslatedText(title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.primaryDark));
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          TranslatedText(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          TranslatedText(label,
              style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}