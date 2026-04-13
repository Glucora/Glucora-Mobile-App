import 'package:flutter/material.dart';
import 'admin_user_list_screen.dart';
import 'admin_device_list_screen.dart';
import 'admin_alert_rules_screen.dart';
import 'admin_role_management_screen.dart';
import 'admin_assignments_screen.dart';  
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText(
          'Admin Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: colors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'User Management'),
          const SizedBox(height: 8),
          _menuCard(
            context,
            icon: Icons.people,
            color: colors.accent,
            title: 'Users',
            subtitle: 'Create, edit, delete user accounts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUserListScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _menuCard(
            context,
            icon: Icons.assignment_ind,
            color: const Color(0xFF9B59B6),
            title: 'Role Management',
            subtitle: 'Assign roles to users',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminRoleManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _menuCard(
            context,
            icon: Icons.link,
            color: const Color(0xFF5B8CF5),
            title: 'Doctor–Patient Assignments',
            subtitle: 'Manage which doctors oversee which patients',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminAssignmentsScreen()),  // ✅ This should work with proper import
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Device & Alert Management'),
          const SizedBox(height: 8),
          _menuCard(
            context,
            icon: Icons.sensors,
            color: colors.warning,
            title: 'Devices',
            subtitle: 'Manage CGM sensors and micropumps',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDeviceListScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _menuCard(
            context,
            icon: Icons.rule,
            color: colors.error,
            title: 'Alert Rules',
            subtitle: 'Configure alert thresholds and conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminAlertRulesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colors = context.colors;
    return TranslatedText(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colors.primaryDark,
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}