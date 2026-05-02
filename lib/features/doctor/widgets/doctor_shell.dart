import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/connection_requests_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/base_profile_tab.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';
import '../screens/doctor_patients_screen.dart';

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
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_alt_1_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Doctor Profile Tab
// ─────────────────────────────────────────────────────
class _DoctorProfileTab extends StatefulWidget {
  const _DoctorProfileTab();

  @override
  State<_DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<_DoctorProfileTab> {
  String _name = '';
  int _age = 0;
  String _email = '';
  String _phone = '';
  String _address = '';
  String _license = '';
  String _specialty = '';
  String _profilePictureUrl = '';
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  // ✅ Incremented on every _loadProfileData call.
  // Passed as ValueKey to BaseProfileTab so Flutter fully destroys and
  // recreates the widget tree — including ProfilePicture — on each reload,
  // preventing any stale in-memory image cache from the previous key.
  int _reloadKey = 0;

  RealtimeChannel? _profileChannel;

  static const List<FaqEntry> _faqs = [
    FaqEntry(
      'How do I monitor my patient\'s glucose levels?',
      'You can view real-time glucose readings and trends from the home dashboard once your patient is connected.',
    ),
    FaqEntry(
      'Will I receive alerts for abnormal readings?',
      'Yes, you will receive alerts when glucose levels are too high or too low, depending on your notification settings.',
    ),
    FaqEntry(
      'Can I manage multiple patients?',
      'Yes, you can connect to and monitor multiple patients from your account.',
    ),
    FaqEntry(
      'What should I do in case of critical readings?',
      'If you notice dangerous glucose levels, contact the patient immediately and seek medical help if necessary.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _subscribeToProfileChanges();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToProfileChanges() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _profileChannel = supabase
        .channel('doctor_profile_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (mounted) _loadProfileData();
          },
        )
        .subscribe();
  }

  Future<void> _loadProfileData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('users')
          .select(
              'full_name, phone_no, email, age, address, profile_picture_url, doctor_profile(liscense_number, speciality)')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        _name = response['full_name'] ?? 'Unknown Doctor';
        _phone = response['phone_no'] ?? 'No Phone';
        _email = response['email'] ?? '';
        _age = (response['age'] as num?)?.toInt() ?? 0;
        _address = response['address'] ?? 'No Address Set';

        // ✅ Strip any existing cache-buster from the stored URL first,
        // then append a fresh timestamp. Without stripping, the URL grows
        // indefinitely and the "base" URL comparison never matches,
        // causing Flutter to treat it as a new network resource but still
        // serve the cached bytes for that path from its HTTP cache.
        final rawUrl = response['profile_picture_url'] as String? ?? '';
        final baseUrl =
            rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;
        _profilePictureUrl = baseUrl.isNotEmpty
            ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
            : '';

        final dynamic profileData = response['doctor_profile'];
        if (profileData != null) {
          final profile =
              (profileData is List) ? profileData.first : profileData;
          _license = profile['liscense_number'] ?? 'Not Set';
          _specialty = profile['speciality'] ?? 'General Practitioner';
        }

        // ✅ Bump key so BaseProfileTab gets a new ValueKey → full rebuild
        _reloadKey++;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch error details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
                'phone': result['phone_no']
              }),
        );

        await _loadProfileData();

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
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return BaseProfileTab(
      // ✅ New key on every reload → Flutter destroys the old widget entirely
      // (including its internal Image cache entry) and builds a fresh one.
      // This is the nuclear option that guarantees no stale image survives.
      key: ValueKey(_reloadKey),
      name: _name,
      age: _age,
      profilePictureUrl: _profilePictureUrl,
      notificationsEnabled: _notificationsEnabled,
      onNotificationsChanged: (v) => setState(() => _notificationsEnabled = v),
      onPictureChanged: _loadProfileData,
      onEditProfile: _editProfile,
      onLogout: () => showLogoutDialog(context),
      faqs: _faqs,
      infoCard: buildInfoCard(
        context,
        child: Column(
          children: [
            buildInfoRow(context, Icons.email_outlined, 'Email', _email),
            Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.phone_outlined, 'Phone', _phone),
            Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.badge_outlined, 'License', _license),
            Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.medical_services_outlined, 'Specialty', _specialty),
            Divider(height: 16, color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.location_on_outlined, 'Address', _address),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Edit Doctor Profile Screen
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
              style: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            buildProfileField(context, 'Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            buildProfileField(context, 'Age', _ageController, Icons.cake_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            buildProfileField(context, 'Speciality', _specialityController,
                Icons.medical_services_outlined),
            const SizedBox(height: 16),
            buildProfileField(context, 'License Number', _licenseController,
                Icons.badge_outlined),
            const SizedBox(height: 16),
            buildProfileField(context, 'Clinic Phone', _phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            buildProfileField(context, 'Clinic Address', _addressController,
                Icons.location_on_outlined),
          ],
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