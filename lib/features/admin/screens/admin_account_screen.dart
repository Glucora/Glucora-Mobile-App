import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';
import 'package:glucora_ai_companion/services/profile_picture_service.dart';
import 'package:glucora_ai_companion/shared/widgets/base_profile_tab.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  String _name = '';
  int _age = 0;
  String _email = '';
  String _phone = '';
  String _address = '';
  String _profilePictureUrl = '';
  bool _loading = true;
  String? _error;
  bool _notificationsEnabled = true;

  static const List<FaqEntry> _faqs = [
    FaqEntry(
      'How do I manage system users?',
      'Navigate to the More tab and select User Management. From there you can add, edit, or deactivate user accounts for doctors, patients, and other admins.',
    ),
    FaqEntry(
      'How do I assign devices to patients?',
      'Go to Device Management under the More tab. Select a device and use the Assign option to link it to a patient. You can also reassign or unassign devices.',
    ),
    FaqEntry(
      'How do I configure alert rules?',
      'Open Alert Rules from the More tab. You can create new rules, set thresholds for glucose levels, and choose notification channels for each alert type.',
    ),
    FaqEntry(
      'How do I manage role permissions?',
      'Access Role Management from the More tab. You can view existing roles, modify their permissions, or create custom roles to control access across the system.',
    ),
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
      if (session == null) throw Exception('Not logged in');

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

  Future<void> _saveUserEdits(
    String newName,
    String newEmail,
    String newPhone,
    String newAddress,
    int newAge,
  ) async {
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

  Future<void> _editProfile() async {
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
        setState(() => _profilePictureUrl = result['profile_picture_url']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colors.primary)));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Failed to load profile', style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _fetchUserData, child: const TranslatedText('Retry')),
            ],
          ),
        ),
      );
    }

    return BaseProfileTab(
      name: _name,
      age: _age,
      roleBadge: 'Administrator',
      profilePictureUrl: _profilePictureUrl,
      notificationsEnabled: _notificationsEnabled,
      onNotificationsChanged: (v) => setState(() => _notificationsEnabled = v),
      onPictureChanged: _fetchUserData,
      onEditProfile: _editProfile,
      onLogout: () => showLogoutDialog(context),
      faqs: _faqs,
      infoCard: buildInfoCard(
        context,
        child: Column(
          children: [
            buildInfoRow(context, Icons.email_outlined, 'Email', _email),
            Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.phone_outlined, 'Phone', _phone.isNotEmpty ? _phone : 'Not set'),
            Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.location_on_outlined, 'Address', _address.isNotEmpty ? _address : 'Not set'),
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
  String _profilePictureUrl = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age.toString());
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
    _profilePictureUrl = widget.profilePictureUrl ?? '';
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
    final userId = Supabase.instance.client.auth.currentUser!.id;
    ProfilePictureService.getProfilePictureUrl(userId).then((url) {
      if (mounted) setState(() => _profilePictureUrl = url ?? '');
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
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              buildProfileField(context, 'Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              buildProfileField(context, 'Age', _ageController, Icons.cake_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              buildProfileField(context, 'Email', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              buildProfileField(context, 'Phone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              buildProfileField(context, 'Address', _addressController, Icons.location_on_outlined),
            ],
          ),
        ),
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