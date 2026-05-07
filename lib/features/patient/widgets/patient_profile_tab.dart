import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/connection_requests_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/weekly_report_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/patient_history_screen.dart';
import 'package:glucora_ai_companion/features/guardian/widgets/guardian_shell.dart';
import 'package:glucora_ai_companion/shared/widgets/base_profile_tab.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';
import 'patient_profile_controller.dart';
import 'edit_profile_screen.dart';
import 'package:glucora_ai_companion/features/patient/widgets/connections_screen.dart';
import 'package:glucora_ai_companion/features/patient/widgets/bluetooth_pairing_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/services/repositories/patient_repository.dart';

// ─────────────────────────────────────────────────────────────
// PatientProfileTab  (StatefulWidget – UI only)
//
// Owns the controller lifecycle (init / dispose).
// Rebuilds via ListenableBuilder whenever the controller notifies.
// Contains zero business logic – all DB calls go through the controller.
// ─────────────────────────────────────────────────────────────
class PatientProfileTab extends StatefulWidget {
  const PatientProfileTab({super.key});

  @override
  State<PatientProfileTab> createState() => _PatientProfileTabState();
}

class _PatientProfileTabState extends State<PatientProfileTab> {
  late final PatientProfileController _controller;
  bool _notificationsEnabled = true;

  static const List<FaqEntry> _faqs = [
    FaqEntry(
      'How do I connect my glucose monitor?',
      'Go to settings and connect your CGM device via Bluetooth.',
    ),
    FaqEntry(
      'What do the glucose ranges mean?',
      'They indicate whether your sugar is low, normal, or high.',
    ),
    FaqEntry(
      'Can I share data with my doctor?',
      'Yes, you can securely share your data with connected doctors.',
    ),
    FaqEntry(
      'How accurate are the predictions?',
      'Predictions are AI-based and improve over time with more data.',
    ),
  ];

  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser!.id;
    _controller = PatientProfileController(
      PatientRepository(Supabase.instance.client),
    )..init(_userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────
  Future<void> _openEditProfile() async {
    final s = _controller.state;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: s.name,
          age: s.age,
          email: s.email,
          phone: s.phone,
          height: s.height,
          weight: s.weight,
          onSave:
              ({
                required String name,
                required String email,
                required String phone,
                required int age,
                required double heightCm,
                required double weightKg,
              }) => _controller.saveProfile(
                userId: _userId,
                name: name,
                email: email,
                phone: phone,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
              ),
        ),
      ),
    );
    if (result != null) _controller.loadProfile(_userId);
  }

  Future<void> _switchToGuardian() async {
    try {
      await _controller.switchToGuardian(_userId);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GuardianMainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('Failed to switch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return BaseProfileTab(
          key: ValueKey(_controller.reloadKey),
          name: state.name,
          age: state.age,
          profilePictureUrl: state.profilePictureUrl,
          notificationsEnabled: _notificationsEnabled,
          onNotificationsChanged: (v) =>
              setState(() => _notificationsEnabled = v),
          onPictureChanged: () => _controller.loadProfile(_userId),
          onEditProfile: _openEditProfile,
          onLogout: () => showLogoutDialog(context),
          faqs: _faqs,
          infoCard: _PatientInfoCard(
            height: state.height,
            weight: state.weight,
          ),
          extraSettingsWidgets: _buildSettingsCards(context),
          aboveLogout: const [],
        );
      },
    );
  }

  List<Widget> _buildSettingsCards(BuildContext context) => [
    _SettingsCard(
      icon: Icons.bluetooth_rounded,
      title: 'Bluetooth Pairing',
      subtitle: 'Connect your CGM sensor or pump',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BluetoothPairingScreen()),
      ),
    ),
    const SizedBox(height: 16),
    _SettingsCard(
      icon: Icons.people_outline_rounded,
      title: 'My Connections & Sharing',
      subtitle: 'Doctors, guardians & location sharing',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
      ),
    ),
    const SizedBox(height: 16),
    _SettingsCard(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Connect with Care Team',
      subtitle: 'Find and connect with doctors & guardians',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ConnectionRequestsScreen(role: 'patient'),
        ),
      ),
    ),
    const SizedBox(height: 16),
    buildSwitchRoleCard(
      context,
      title: 'Switch to Guardian View',
      subtitle: 'Switch your role to guardian',
      onTap: _switchToGuardian,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────
// _PatientInfoCard  (private presentational widget)
// ─────────────────────────────────────────────────────────────
class _PatientInfoCard extends StatelessWidget {
  final String height;
  final String weight;

  const _PatientInfoCard({required this.height, required this.weight});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        buildInfoCard(
          context,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildInfoColumn(context, 'Height', height),
              Container(
                width: 1,
                height: 30,
                color: colors.textSecondary.withValues(alpha: 0.2),
              ),
              buildInfoColumn(context, 'Weight', weight),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TranslatedText(
            'Reports & History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                icon: Icons.insert_chart_outlined_rounded,
                label: 'Weekly Report',
                iconColor: colors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportCard(
                icon: Icons.history_rounded,
                label: 'History & Export',
                iconColor: const Color(0xFF5B8CF5),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientHistoryScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _ReportCard  (private presentational widget)
// ─────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            TranslatedText(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SettingsCard  (private presentational widget)
//
// Extracted from _ProfileTabState so it can be const-constructed
// and tested independently.
// ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
