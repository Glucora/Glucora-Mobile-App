import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/features/doctor/widgets/doctor_shell.dart';
import 'package:glucora_ai_companion/features/guardian/widgets/guardian_shell.dart';
import 'package:glucora_ai_companion/features/patient/widgets/patient_shell.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _saving = false;

Future<void> _saveRoleToProfiles({
  required String userId,
  required String role,
}) async {
  await Supabase.instance.client
      .from('users')
      .update({'role': role})
      .eq('id', userId)
      .select()
      .single();
}

Future<void> _selectRole(String role) async {
  if (_saving) return;
  setState(() => _saving = true);

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // 1. Update auth metadata
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'role': role}),
    );

    // 2. Update users table role
    await Supabase.instance.client
        .from('users')
        .update({'role': role})
        .eq('id', user.id);

    // 3. Create role-specific profile using upsert — never crashes on duplicate
    if (role == 'doctor') {
      await Supabase.instance.client
          .from('doctor_profile')
          .upsert(
            {
              'user_id': user.id,
              'speciality': '',
            },
            onConflict: 'user_id',
          );
    } else if (role == 'patient') {
      await Supabase.instance.client
          .from('patient_profile')
          .upsert(
            {
              'user_id': user.id,
              'height_cm': 0,
              'weight_kg': 0,
            },
            onConflict: 'user_id',
          );
    } else if (role == 'guardian') {
      await Supabase.instance.client
          .from('guardian_profile')
          .upsert(
            {'user_id': user.id},
            onConflict: 'user_id',
          );
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _targetForRole(role)),
      (route) => false,
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: Colors.red),
    );
  } catch (ex) {
    if (!mounted) return;
    debugPrint('Role save error FULL: $ex');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ex.toString()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
      ),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}
  Widget _targetForRole(String role) {
    switch (role) {
      case 'patient':
        return const PatientNavigation();
      case 'doctor':
        return const DoctorMainScreen();
      case 'guardian':
        return const GuardianMainScreen();
      default:
        return const PatientNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primaryDark,
        elevation: 0,
        title: const TranslatedText(
          'Select Role',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'Welcome to Glucora',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TranslatedText(
                'Choose your role to personalize your experience.',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: _roleCard(
                          role: 'patient',
                          title: 'Patient',
                          subtitle: 'Track your data and daily logs',
                          icon: Icons.favorite_outline,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: _roleCard(
                          role: 'doctor',
                          title: 'Doctor',
                          subtitle: 'Review patients and alerts',
                          icon: Icons.medical_services_outlined,
                          color: const Color(0xFF5B8CF5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: _roleCard(
                          role: 'guardian',
                          title: 'Guardian',
                          subtitle: 'Monitor loved ones and updates',
                          icon: Icons.shield_outlined,
                          color: const Color(0xFF9B59B6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _saving ? null : () => _selectRole(role),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              TranslatedText(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              TranslatedText(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
