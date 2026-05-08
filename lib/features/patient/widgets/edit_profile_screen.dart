import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';

// ─────────────────────────────────────────────────────────────
// EditProfileScreen
//
// Receives current values and an [onSave] callback so it is
// completely decoupled from Supabase – the controller handles
// the actual persistence, making this screen easily testable.
// ─────────────────────────────────────────────────────────────
typedef SaveProfileCallback = Future<void> Function({
  required String name,
  required String email,
  required String phone,
  required int age,
  required double heightCm,
  required double weightKg,
});

class EditProfileScreen extends StatefulWidget {
  final String name;
  final int age;
  final String? email;
  final String? phone;
  final String height;
  final String weight;
  final SaveProfileCallback onSave;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.age,
    this.email,
    this.phone,
    required this.height,
    required this.weight,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController   = TextEditingController(text: widget.name);
    _ageController    = TextEditingController(text: widget.age.toString());
    _heightController = TextEditingController(text: widget.height);
    _weightController = TextEditingController(text: widget.weight);
    _emailController  = TextEditingController(text: widget.email);
    _phoneController  = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────
  double _parseNumber(String raw) =>
      double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  // ── Save ──────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        name:      _nameController.text.trim(),
        email:     _emailController.text.trim(),
        phone:     _phoneController.text.trim(),
        age:       int.tryParse(_ageController.text) ?? 0,
        heightCm:  _parseNumber(_heightController.text),
        weightKg:  _parseNumber(_weightController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // signal success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary),
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
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TranslatedText(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildProfileField(context, 'Name', _nameController,
                Icons.person_outline),
            const SizedBox(height: 16),
            buildProfileField(context, 'Email', _emailController,
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            buildProfileField(context, 'Height', _heightController,
                Icons.height,
                keyboardType: TextInputType.number, suffix: 'cm'),
            const SizedBox(height: 16),
            buildProfileField(context, 'Weight', _weightController,
                Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number, suffix: 'kg'),
            const SizedBox(height: 16),
            buildProfileField(context, 'Age', _ageController,
                Icons.cake_outlined,
                keyboardType: TextInputType.number, suffix: 'years'),
            const SizedBox(height: 16),
            buildProfileField(context, 'Phone Number', _phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }
}
