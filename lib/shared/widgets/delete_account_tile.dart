// lib\shared\widgets\delete_account_tile.dart
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

      print('Deleting account for role: $role');

      // Delete role-specific data first (using try-catch for each, like your friend's code)
      if (role == 'patient') {
        // Get patient profile id
        try {
          final profileResponse = await supabase
              .from('patient_profile')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (profileResponse != null) {
            try { await supabase.from('glucose_readings').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
            try { await supabase.from('insulin_doses').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
            try { await supabase.from('ai_predictions').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
            try { await supabase.from('insulin_on_board').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
            try { await supabase.from('alerts').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
            try { await supabase.from('care_plans').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
          }
        } catch (_) {}

        try { await supabase.from('patient_profile').delete().eq('user_id', user.id); } catch (_) {}
        try { await supabase.from('guardian_patient_connections').delete().eq('patient_id', user.id); } catch (_) {}
        try { await supabase.from('doctor_patient_connections').delete().eq('patient_id', user.id); } catch (_) {}
        try { await supabase.from('patient_locations').delete().eq('patient_id', user.id); } catch (_) {}
        try { await supabase.from('devices').delete().eq('patient_id', user.id); } catch (_) {}

      } else if (role == 'guardian') {
        try { await supabase.from('guardian_patient_connections').delete().eq('guardian_id', user.id); } catch (_) {}
        try { await supabase.from('guardian_profile').delete().eq('user_id', user.id); } catch (_) {}

      } else if (role == 'doctor') {
        try { await supabase.from('care_plans').delete().eq('doctor_id', user.id); } catch (_) {}
        try { await supabase.from('doctor_patient_connections').delete().eq('doctor_id', user.id); } catch (_) {}
        try { await supabase.from('doctor_profile').delete().eq('user_id', user.id); } catch (_) {}

      } else if (role == 'admin') {
        try { await supabase.from('admin_logs').delete().eq('admin_user_id', user.id); } catch (_) {}
      }

      // Delete device tokens
      try { await supabase.from('device_tokens').delete().eq('user_id', user.id); } catch (_) {}

      // Finally, delete the user from auth using RPC
      await supabase.rpc('delete_user_by_id', params: {'user_id': user.id});

      // Sign out
      await supabase.auth.signOut();
      
      // Dismiss loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Account deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login-screen',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      
      // Dismiss loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to delete account: $e'),
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