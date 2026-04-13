import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => _showDeleteAccountDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.error.withValues(alpha: 0.4)),
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
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: colors.error,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    'Permanently remove your account',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.error),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        icon: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_forever_rounded,
            color: colors.error,
            size: 32,
          ),
        ),
        title: TranslatedText(
          'Delete Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        content: TranslatedText(
          'Are you sure you want to delete your account?\n\n'
          'This action is permanent and cannot be undone — '
          'all your data will be lost and cannot be retrieved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colors.textSecondary.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: TranslatedText(
                'Cancel',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteAccount(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const TranslatedText(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Get user role first
      final userData = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final role = userData['role'] as String? ?? '';

      // Delete role-specific data first
      if (role == 'patient') {
        // Get patient profile id
        final patientProfile = await supabase
            .from('patient_profile')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (patientProfile != null) {
          // Delete patient-specific data
          await supabase.from('glucose_readings').delete().eq('patient_id', patientProfile['id']);
          await supabase.from('insulin_doses').delete().eq('patient_id', patientProfile['id']);
          await supabase.from('patient_profile').delete().eq('user_id', user.id);
        }
        
        // Delete connections where user is patient
        await supabase.from('guardian_patient_connections').delete().eq('patient_id', user.id);
        await supabase.from('doctor_patient_connections').delete().eq('patient_id', user.id);
        await supabase.from('patient_locations').delete().eq('patient_id', user.id);
        
      } else if (role == 'guardian') {
        // Delete connections where user is guardian
        await supabase.from('guardian_patient_connections').delete().eq('guardian_id', user.id);
        
      } else if (role == 'doctor') {
        // Get doctor profile id
        final doctorProfile = await supabase
            .from('doctor_profile')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (doctorProfile != null) {
          // Delete doctor-specific data
          await supabase.from('care_plans').delete().eq('doctor_id', user.id);
          await supabase.from('doctor_profile').delete().eq('user_id', user.id);
        }
        
        // Delete connections where user is doctor
        await supabase.from('doctor_patient_connections').delete().eq('doctor_id', user.id);
      }

      // Common deletions for all roles
      await supabase.from('devices').delete().eq('patient_id', user.id);
      
      // Call RPC to delete user account
      final response = await supabase.rpc('delete_user_account');
      
      print('Delete response: $response');
      
      if (response != null && response['success'] == true) {
        await supabase.auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login-screen',
            (route) => false,
          );
        }
      } else {
        throw Exception(response?['error'] ?? 'Failed to delete account');
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}