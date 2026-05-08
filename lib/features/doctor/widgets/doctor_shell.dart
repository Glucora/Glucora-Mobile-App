import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/connection_requests_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/base_profile_tab.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';
import 'package:glucora_ai_companion/services/repositories/doctor_repository.dart';
import '../screens/doctor_patients_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell (bottom nav host) — no data logic, pure navigation
// ─────────────────────────────────────────────────────────────────────────────

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
        onTap: (index) => setState(() => _currentIndex = index),
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

// ─────────────────────────────────────────────────────────────────────────────
// Doctor Profile Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorProfileTab extends StatefulWidget {
  const _DoctorProfileTab();

  @override
  State<_DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<_DoctorProfileTab> {
  // ── Repository ─────────────────────────────────────────────────────────────
  // Only touch Supabase here to hand the client to the repository.
  // Nothing else in this file calls Supabase directly.
  late final DoctorRepository _repo =
      DoctorRepository(Supabase.instance.client);

  // Resolved once in initState so we don't call Supabase.instance repeatedly
  late final String _userId;

  // ── State ──────────────────────────────────────────────────────────────────
  DoctorProfile? _profile;
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  /// Bumped on every successful load so BaseProfileTab gets a new ValueKey
  /// and fully rebuilds (including its ProfilePicture widget).
  int _reloadKey = 0;

  RealtimeChannel? _profileChannel;

  // ── FAQ content ────────────────────────────────────────────────────────────
  static const List<FaqEntry> _faqs = [
    FaqEntry(
      'How do I monitor my patient\'s glucose levels?',
      'You can view real-time glucose readings and trends from the home '
          'dashboard once your patient is connected.',
    ),
    FaqEntry(
      'Will I receive alerts for abnormal readings?',
      'Yes, you will receive alerts when glucose levels are too high or too '
          'low, depending on your notification settings.',
    ),
    FaqEntry(
      'Can I manage multiple patients?',
      'Yes, you can connect to and monitor multiple patients from your account.',
    ),
    FaqEntry(
      'What should I do in case of critical readings?',
      'If you notice dangerous glucose levels, contact the patient immediately '
          'and seek medical help if necessary.',
    ),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Resolve userId once — avoids repeated Supabase.instance calls
    _userId = Supabase.instance.client.auth.currentUser!.id;
    _loadProfile();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final profile = await _repo.getDoctorProfile(_userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _reloadKey++;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToChanges() {
    _profileChannel = _repo.subscribeToDoctorProfileChanges(
      userId: _userId,
      onChanged: () {
        if (mounted) _loadProfile();
      },
    );
  }

  // ── Edit profile ───────────────────────────────────────────────────────────

  Future<void> _editProfile() async {
    if (_profile == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditDoctorProfileScreen(
          name: _profile!.name,
          age: _profile!.age,
          email: _profile!.email,
          phone: _profile!.phone,
          address: _profile!.address,
          specialty: _profile!.specialty,
          license: _profile!.license,
        ),
      ),
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      await _repo.updateDoctorProfile(
        userId: _userId,
        fullName: result['full_name'] as String,
        phoneNo: result['phone_no'] as String,
        age: result['age'] as int,
        address: result['address'] as String,
        specialty: result['speciality'] as String,
        licenseNumber: result['license_number'] as String,
      );

      // Auth metadata update still needs Supabase auth client directly
      // because there is no auth abstraction yet — acceptable for now.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'full_name': result['full_name'],
          'phone': result['phone_no'],
        }),
      );

      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: TranslatedText('Failed to load profile.'));
    }

    return BaseProfileTab(
      key: ValueKey(_reloadKey),
      name: profile.name,
      age: profile.age,
      profilePictureUrl: profile.profilePictureUrl,
      notificationsEnabled: _notificationsEnabled,
      onNotificationsChanged: (v) =>
          setState(() => _notificationsEnabled = v),
      onPictureChanged: _loadProfile,
      onEditProfile: _editProfile,
      onLogout: () => showLogoutDialog(context),
      faqs: _faqs,
      infoCard: buildInfoCard(
        context,
        child: Column(
          children: [
            buildInfoRow(
                context, Icons.email_outlined, 'Email', profile.email),
            Divider(
                height: 16,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(
                context, Icons.phone_outlined, 'Phone', profile.phone),
            Divider(
                height: 16,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(
                context, Icons.badge_outlined, 'License', profile.license),
            Divider(
                height: 16,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(
                context,
                Icons.medical_services_outlined,
                'Specialty',
                profile.specialty),
            Divider(
                height: 16,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(
                context,
                Icons.location_on_outlined,
                'Address',
                profile.address),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Doctor Profile Screen — pure UI, returns a map, touches no data layer
// ─────────────────────────────────────────────────────────────────────────────

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

class _EditDoctorProfileScreenState
    extends State<_EditDoctorProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _specialityController;
  late final TextEditingController _licenseController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

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
              color: colors.textPrimary, fontWeight: FontWeight.bold),
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
            buildProfileField(
                context, 'Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            buildProfileField(
              context, 'Age', _ageController, Icons.cake_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            buildProfileField(
                context,
                'Speciality',
                _specialityController,
                Icons.medical_services_outlined),
            const SizedBox(height: 16),
            buildProfileField(
                context,
                'License Number',
                _licenseController,
                Icons.badge_outlined),
            const SizedBox(height: 16),
            buildProfileField(
              context, 'Clinic Phone', _phoneController, Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            buildProfileField(
                context,
                'Clinic Address',
                _addressController,
                Icons.location_on_outlined),
          ],
        ),
      ),
    );
  }
}