// lib\features\guardian\screens\guardian_main_screen.dart
import 'package:flutter/material.dart';
import '../screens/guardian_home_screen.dart';
import 'package:glucora_ai_companion/shared/screens/connection_requests_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/features/patient/widgets/patient_shell.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/language_selection_screen.dart';

class GuardianMainScreen extends StatefulWidget {
  const GuardianMainScreen({super.key});
  @override
  State<GuardianMainScreen> createState() => _GuardianMainScreenState();
}

class _GuardianMainScreenState extends State<GuardianMainScreen> {
  int _index = 0;
  int _pendingRequests = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const GuardianHomeScreen(),
      ConnectionRequestsScreen(
        role: 'guardian',
        onIncomingCountChanged: (count) {
          if (mounted) setState(() => _pendingRequests = count);
        },
      ),
      const _GuardianProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Home',
                  colors,
                ),
                _item(
                  1,
                  Icons.people_rounded,
                  Icons.people_outline_rounded,
                  'Requests',
                  colors,
                  badge: _pendingRequests,
                ),
                _item(
                  2,
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profile',
                  colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    int idx,
    IconData active,
    IconData inactive,
    String label,
    GlucoraColors colors, {
    int badge = 0,
  }) {
    final sel = _index == idx;
    return GestureDetector(
      onTap: () => setState(() => _index = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? colors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  sel ? active : inactive,
                  color: sel ? colors.accent : colors.textSecondary,
                  size: 26,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE63946),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: TranslatedText(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            TranslatedText(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? colors.accent : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Guardian Settings Screen
// ─────────────────────────────────────────────────────
class _GuardianSettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final void Function(bool notifications) onSettingsChanged;

  const _GuardianSettingsScreen({
    required this.notificationsEnabled,
    required this.onSettingsChanged,
  });

  @override
  State<_GuardianSettingsScreen> createState() =>
      _GuardianSettingsScreenState();
}

class _GuardianSettingsScreenState extends State<_GuardianSettingsScreen> {
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _settingsToggle(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Receive system alerts and updates',
              color: colors.primary,
              value: _notifications,
              onChanged: (val) {
                setState(() => _notifications = val);
                widget.onSettingsChanged(_notifications);
              },
            ),
            const SizedBox(height: 16),
            _settingsToggle(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              color: const Color(0xFF5B8CF5),
              value: isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
            const SizedBox(height: 16),
            _settingsNavigationTile(
              context,
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'Choose your preferred language',
              color: const Color(0xFF2BB6A3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageSelectionScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // ── DELETE ACCOUNT TILE ──────────────────────────────────
            _deleteAccountTile(context),
          ],
        ),
      ),
    );
  }

  // ── DELETE ACCOUNT TILE ────────────────────────────────────────────
  Widget _deleteAccountTile(BuildContext context) {
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

  // ── DELETE ACCOUNT CONFIRMATION DIALOG ────────────────────────────
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
                await _deleteAccount();
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

  // ── DELETE ACCOUNT LOGIC ───────────────────────────────────────────
 Future<void> _deleteAccount() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  // Show loading indicator while deleting
  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  try {
    // Call the RPC function to delete the account
    final response = await supabase.rpc('delete_user_account');
    
    print('Delete response: $response'); // For debugging
    
    // Check if deletion was successful
    if (response != null && response['success'] == true) {
      // Sign out locally
      await supabase.auth.signOut();

      // Navigate to login and clear all routes
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login-screen',
        (route) => false,
      );
    } else {
      throw Exception(response?['error'] ?? 'Failed to delete account');
    }
  } catch (e) {
    debugPrint('Delete account error: $e');
    
    // Dismiss loading dialog on error
    if (mounted) Navigator.of(context).pop();

    if (mounted) {
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

  // ── SHARED UI HELPERS ──────────────────────────────────────────────
  Widget _settingsToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.3)),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _settingsNavigationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
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

// ─────────────────────────────────────────────────────
// Edit Guardian Profile Screen
// ─────────────────────────────────────────────────────
class _EditGuardianProfileScreen extends StatefulWidget {
  final String name;
  final int age;
  final String email;
  final String phone;

  const _EditGuardianProfileScreen({
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
  });

  @override
  State<_EditGuardianProfileScreen> createState() =>
      _EditGuardianProfileScreenState();
}

class _EditGuardianProfileScreenState
    extends State<_EditGuardianProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age.toString());
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Edit Profile',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: TranslatedText(
              'Save',
              style: TextStyle(
                color: colors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField(context, 'Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Age',
              _ageController,
              Icons.cake_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Email',
              _emailController,
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Phone Number',
              _phoneController,
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _save() {
    final updatedName = _nameController.text.trim();
    final updatedAge = int.tryParse(_ageController.text.trim()) ?? widget.age;
    final updatedEmail = _emailController.text.trim();
    final updatedPhone = _phoneController.text.trim();

    if (updatedName.isEmpty || updatedEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const TranslatedText('Name and Email are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'name': updatedName,
      'age': updatedAge,
      'email': updatedEmail,
      'phone': updatedPhone,
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────
// Guardian's Profile Tab (with Settings icon)
// ─────────────────────────────────────────────────────
class _GuardianProfileTab extends StatefulWidget {
  const _GuardianProfileTab();

  @override
  State<_GuardianProfileTab> createState() => _GuardianProfileTabState();
}

class _GuardianProfileTabState extends State<_GuardianProfileTab> {
  String _name = "";
  int _age = 0;
  String _email = "";
  String _phone = "";
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  int? _openFaqIndex;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('users')
          .select('full_name, email, phone_no, age')
          .eq('id', user.id)
          .single();

      setState(() {
        _name = data['full_name'] ?? "Guardian";
        _email = data['email'] ?? "";
        _phone = data['phone_no'] ?? "";
        _age = (data['age'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _editProfile() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => _EditGuardianProfileScreen(
              name: _name,
              age: _age,
              email: _email,
              phone: _phone,
            ),
          ),
        );

    if (result != null) {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      setState(() => _isLoading = true);

      try {
        await supabase.auth.updateUser(
          UserAttributes(
            email: result['email'],
            data: {'full_name': result['name'], 'phone': result['phone']},
          ),
        );

        await supabase
            .from('users')
            .update({
              'full_name': result['name'],
              'email': result['email'],
              'phone_no': result['phone'],
              'age': result['age'],
            })
            .eq('id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: TranslatedText('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadProfileData();
      } catch (e) {
        debugPrint("Update error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText('Update failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Log Out'),
        content: const TranslatedText(
          'Are you sure to log out of your account?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: TranslatedText(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {
                // Continue navigation even if remote sign out fails.
              }

              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const TranslatedText('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText(
                  "Profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colors.textSecondary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _GuardianSettingsScreen(
                          notificationsEnabled: _notificationsEnabled,
                          onSettingsChanged: (notifications) {
                            setState(
                              () => _notificationsEnabled = notifications,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslatedText(
                        _name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _editProfile,
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    "$_age years",
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoColumn(context, "Email", _email),
                  Divider(color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoColumn(context, "Phone", _phone),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TranslatedText(
              "FAQs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _faqItem(
              context,
              0,
              "How do I monitor my patient's glucose levels?",
              "You can view real-time glucose readings and trends from the home dashboard once your patient is connected.",
            ),
            _faqItem(
              context,
              1,
              "Will I receive alerts for abnormal readings?",
              "Yes, you will receive alerts when glucose levels are too high or too low, depending on your notification settings.",
            ),
            _faqItem(
              context,
              2,
              "Can I manage multiple patients?",
              "Yes, you can connect to and monitor multiple patients from your account.",
            ),
            _faqItem(
              context,
              3,
              "What should I do in case of critical readings?",
              "If you notice dangerous glucose levels, contact the patient immediately and seek medical help if necessary.",
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final supabase = Supabase.instance.client;
                  final userId = supabase.auth.currentUser?.id;
                  if (userId == null) return;

                  try {
                    await supabase
                        .from('users')
                        .update({'role': 'patient'})
                        .eq('id', userId);

                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const PatientNavigation(),
                      ),
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const TranslatedText('Switch to Patient View'),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: TranslatedText(
                    "Log Out",
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          label,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        TranslatedText(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _faqItem(
    BuildContext context,
    int index,
    String question,
    String answer,
  ) {
    final colors = context.colors;
    final isOpen = _openFaqIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _openFaqIndex = _openFaqIndex == index ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TranslatedText(
                    question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 10),
              TranslatedText(
                answer,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}