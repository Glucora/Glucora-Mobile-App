import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/settings_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';
import 'package:glucora_ai_companion/services/profile_picture_service.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  String _name = "";
  int _age = 0;
  String _email = "";
  String _phone = "";
  String _address = "";
  String _profilePictureUrl = "";
  bool _loading = true;
  String? _error;

  bool _notificationsEnabled = true;
  int _expandedFaqIndex = -1;

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I manage system users?',
      'a': 'Navigate to the More tab and select User Management. From there you can add, edit, or deactivate user accounts for doctors, patients, and other admins.',
    },
    {
      'q': 'How do I assign devices to patients?',
      'a': 'Go to Device Management under the More tab. Select a device and use the Assign option to link it to a patient. You can also reassign or unassign devices.',
    },
    {
      'q': 'How do I configure alert rules?',
      'a': 'Open Alert Rules from the More tab. You can create new rules, set thresholds for glucose levels, and choose notification channels for each alert type.',
    },
    {
      'q': 'How do I manage role permissions?',
      'a': 'Access Role Management from the More tab. You can view existing roles, modify their permissions, or create custom roles to control access across the system.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('Not logged in');
      }

      final response = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, role, is_active, created_at, phone_no, age, address, profile_picture_url')
          .eq('id', session.user.id)
          .single();

      setState(() {
        _name = response['full_name'] as String? ?? 'Admin User';
        _email = response['email'] as String? ?? '';
        _phone = response['phone_no'] as String? ?? '';
        _age = response['age'] as int? ?? 0;
        _address = response['address'] as String? ?? '';
        _profilePictureUrl = response['profile_picture_url'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
            child: TranslatedText('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}

              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login-screen', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const TranslatedText('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserEdits(String newName, String newEmail, String newPhone, String newAddress, int newAge) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      await Supabase.instance.client
          .from('users')
          .update({
            'full_name': newName,
            'email': newEmail,
            'phone_no': newPhone,
            'age': newAge,
            'address': newAddress,
          })
          .eq('id', session.user.id);

      setState(() {
        _name = newName;
        _email = newEmail;
        _phone = newPhone;
        _address = newAddress;
        _age = newAge;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditAdminProfileScreen(
          name: _name,
          age: _age,
          email: _email,
          phone: _phone,
          address: _address,
          profilePictureUrl: _profilePictureUrl,
        ),
      ),
    );
    if (result != null) {
      await _saveUserEdits(
        result['name'],
        result['email'],
        result['phone'],
        result['address'],
        result['age'],
      );
      if (result['profile_picture_url'] != null) {
        setState(() {
          _profilePictureUrl = result['profile_picture_url'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Failed to load profile', style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchUserData,
                child: const TranslatedText('Retry'),
              ),
            ],
          ),
        ),
      );
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
                        builder: (_) => SettingsScreen(
                          notificationsEnabled: _notificationsEnabled,
                          onNotificationsChanged: (notifications) {
                            setState(() => _notificationsEnabled = notifications);
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
                  ProfilePicture(
                    userId: Supabase.instance.client.auth.currentUser!.id,
                    imageUrl: _profilePictureUrl,
                    size: 90,
                    isEditable: true,
                    onPictureChanged: () => _fetchUserData(),
                    displayName: _name,
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TranslatedText(
                      "Administrator",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
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
                children: [
                  _infoRow(context, Icons.email_outlined, "Email", _email),
                  Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoRow(context, Icons.phone_outlined, "Phone", _phone.isNotEmpty ? _phone : "Not set"),
                  Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
                  _infoRow(
                    context,
                    Icons.location_on_outlined,
                    "Address",
                    _address.isNotEmpty ? _address : "Not set",
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
            for (int i = 0; i < _faqs.length; i++)
              _faqItem(context, i, _faqs[i]['q']!, _faqs[i]['a']!),
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

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
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
    final isExpanded = _expandedFaqIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _expandedFaqIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? colors.primary.withValues(alpha: 0.3)
                : colors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TranslatedText(
                    question,
                    style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              TranslatedText(
                answer,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Edit Admin Profile Screen
// ─────────────────────────────────────────────────────
class _EditAdminProfileScreen extends StatefulWidget {
  final String name;
  final int age;
  final String email;
  final String phone;
  final String address;
  final String? profilePictureUrl;

  const _EditAdminProfileScreen({
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
    this.profilePictureUrl,
  });

  @override
  State<_EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<_EditAdminProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String _profilePictureUrl = "";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age.toString());
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
    _profilePictureUrl = widget.profilePictureUrl ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onPictureChanged() {
    // Refresh the profile picture URL after upload
    final userId = Supabase.instance.client.auth.currentUser!.id;
    ProfilePictureService.getProfilePictureUrl(userId).then((url) {
      if (mounted) {
        setState(() {
          _profilePictureUrl = url ?? "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Edit Profile',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: TranslatedText(
              'Save',
              style: TextStyle(color: colors.primary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    ProfilePicture(
                      userId: Supabase.instance.client.auth.currentUser!.id,
                      imageUrl: _profilePictureUrl,
                      size: 100,
                      isEditable: true,
                      onPictureChanged: _onPictureChanged,
                      displayName: _nameController.text,
                    ),
                    const SizedBox(height: 8),
                    TranslatedText(
                      'Tap to change profile picture',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildField(context, 'Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildField(context, 'Age', _ageController, Icons.cake_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField(context, 'Email', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField(context, 'Phone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(context, 'Address', _addressController, Icons.location_on_outlined),
            ],
          ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _save() {
    final updatedName = _nameController.text.trim();
    final updatedAge = int.tryParse(_ageController.text.trim()) ?? widget.age;
    final updatedEmail = _emailController.text.trim();
    final updatedPhone = _phoneController.text.trim();
    final updatedAddress = _addressController.text.trim();

    Navigator.pop(context, {
      'name': updatedName.isEmpty ? widget.name : updatedName,
      'age': updatedAge,
      'email': updatedEmail.isEmpty ? widget.email : updatedEmail,
      'phone': updatedPhone.isEmpty ? widget.phone : updatedPhone,
      'address': updatedAddress.isEmpty ? widget.address : updatedAddress,
      'profile_picture_url': _profilePictureUrl,
    });
  }
}