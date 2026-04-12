// \lib\features\doctor\screens\doctor_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/translated_text.dart';
import 'package:glucora_ai_companion/shared/language_selection_screen.dart';
import 'doctor_patients_screen.dart';
import 'package:glucora_ai_companion/shared/connection_requests_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DoctorPatientsScreen(),
    const ConnectionRequestsScreen(role: 'doctor'),
    const _DoctorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: colors.accent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Edit Doctor Profile Screen (with Address)
// ─────────────────────────────────────────────────────
class _EditDoctorProfileScreen extends StatefulWidget {
  final String name;
  final int age;
  final String email;
  final String phone;
  final String address;
  final String specialty;
  final String license;

  const _EditDoctorProfileScreen({
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
    required this.specialty,
    required this.license,
  });

  @override
  State<_EditDoctorProfileScreen> createState() =>
      _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<_EditDoctorProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _specialityController;
  late TextEditingController _licenseController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age.toString());
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
    _specialityController = TextEditingController(text: widget.specialty);
    _licenseController = TextEditingController(text: widget.license);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _specialityController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
        child: ListView(
          children: [
            _buildField(
              context,
              'Full Name',
              _nameController,
              Icons.person_outline,
            ),
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
              'Speciality',
              _specialityController,
              Icons.medical_services_outlined,
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'License Number',
              _licenseController,
              Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Clinic Phone',
              _phoneController,
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Clinic Address',
              _addressController,
              Icons.location_on_outlined,
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
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
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
    Navigator.pop(context, {
      'full_name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'speciality': _specialityController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'phone_no': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    });
  }
}

// ─────────────────────────────────────────────────────
// Doctor Settings Screen (like Admin's settings screen)
// ─────────────────────────────────────────────────────
class _DoctorSettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final void Function(bool notifications) onSettingsChanged;

  const _DoctorSettingsScreen({
    required this.notificationsEnabled,
    required this.onSettingsChanged,
  });

  @override
  State<_DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<_DoctorSettingsScreen> {
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
            // ✅ LANGUAGE SETTINGS OPTION (same as Admin)
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
          ],
        ),
      ),
    );
  }

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
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Doctor's Profile Tab (with Settings icon that opens DoctorSettingsScreen)
// ─────────────────────────────────────────────────────
class _DoctorProfileTab extends StatefulWidget {
  const _DoctorProfileTab();

  @override
  State<_DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<_DoctorProfileTab> {
  String _name = "";
  int _age = 0;
  String _email = "";
  String _phone = "";
  String _address = "";
  String _license = "";
  String _specialty = "";
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  final Set<int> _openFaqs = {};


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
      final response = await supabase
          .from('users')
          .select(
            'full_name, phone_no, email, age, address, doctor_profile(liscense_number, speciality)',
          )
          .eq('id', user.id)
          .single();

      setState(() {
        _name = response['full_name'] ?? "Unknown Doctor";
        _phone = response['phone_no'] ?? "No Phone";
        _email = response['email'] ?? "";
        _age = (response['age'] as num?)?.toInt() ?? 0;
        _address = response['address'] ?? "No Address Set";

        final dynamic profileData = response['doctor_profile'];
        if (profileData != null) {
          final profile = (profileData is List)
              ? profileData.first
              : profileData;
          _license = profile['liscense_number'] ?? "Not Set";
          _specialty = profile['speciality'] ?? "General Practitioner";
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error details: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Log Out'),
        content: const TranslatedText('Are you sure to log out of your account?'),
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
                        builder: (_) => _DoctorSettingsScreen(
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
            // Contact information card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.textSecondary.withValues(alpha: 0.3)),
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
                  _infoRow(context, Icons.email_outlined, "Email", _email),
                  Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoRow(context, Icons.phone_outlined, "Phone", _phone),
                  Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoRow(context, Icons.badge_outlined, "License", _license),
                  Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoRow(
                    context,
                    Icons.medical_services_outlined,
                    "Specialty",
                    _specialty,
                  ),
                  Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoRow(
                    context,
                    Icons.location_on_outlined,
                    "Address",
                    _address,
                  ),
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

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = context.colors;
    
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: TranslatedText(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        Expanded(
          child: TranslatedText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
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
  final isOpen = _openFaqs.contains(index);

  return GestureDetector(
    onTap: () {
      setState(() {
        if (isOpen) {
          _openFaqs.remove(index);
        } else {
          _openFaqs.add(index);
        }
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

          // ✅ ANSWER (this was missing!)
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
  Future<void> _editProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditDoctorProfileScreen(
          name: _name,
          age: _age,
          email: _email,
          phone: _phone,
          address: _address,
          specialty: _specialty,
          license: _license,
        ),
      ),
    );

    if (result != null) {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      setState(() => _isLoading = true);

      try {
        await supabase
            .from('users')
            .update({
              'full_name': result['full_name'],
              'phone_no': result['phone_no'],
              'age': result['age'],
              'address': result['address'],
            })
            .eq('id', userId!);

        await supabase
            .from('doctor_profile')
            .update({
              'speciality': result['speciality'],
              'liscense_number': result['license_number'],
            })
            .eq('user_id', userId);

        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': result['full_name'],
              'phone': result['phone_no'],
            },
          ),
        );

        await _loadProfileData();
      } catch (e) {
        debugPrint("Update error: $e");
      } finally {
        setState(() => _isLoading = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}