import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/connection_requests_screen.dart';
import 'package:glucora_ai_companion/features/patient/widgets/patient_shell.dart';
import 'package:glucora_ai_companion/shared/widgets/base_profile_tab.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';
import '../screens/guardian_home_screen.dart';

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
          border: Border(top: BorderSide(color: colors.textSecondary.withValues(alpha: 0.2), width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(0, Icons.home_rounded, Icons.home_outlined, 'Home', colors),
                _item(1, Icons.people_rounded, Icons.people_outline_rounded, 'Requests', colors, badge: _pendingRequests),
                _item(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile', colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int idx, IconData active, IconData inactive, String label, GlucoraColors colors, {int badge = 0}) {
    final sel = _index == idx;
    return GestureDetector(
      onTap: () => setState(() => _index = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? colors.accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(sel ? active : inactive, color: sel ? colors.accent : colors.textSecondary, size: 26),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
                      child: Center(
                        child: TranslatedText(
                          '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
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
// Guardian Profile Tab
// ─────────────────────────────────────────────────────
class _GuardianProfileTab extends StatefulWidget {
  const _GuardianProfileTab();

  @override
  State<_GuardianProfileTab> createState() => _GuardianProfileTabState();
}

class _GuardianProfileTabState extends State<_GuardianProfileTab> {
  String _name = '';
  int _age = 0;
  String _email = '';
  String _phone = '';
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
        .channel('guardian_profile_$userId')
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
      final data = await supabase
          .from('users')
          .select('full_name, email, phone_no, age, profile_picture_url')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        _name = data['full_name'] ?? 'Guardian';
        _email = data['email'] ?? '';
        _phone = data['phone_no'] ?? '';
        _age = (data['age'] as num?)?.toInt() ?? 0;

        // ✅ Strip any existing cache-buster from the stored URL first,
        // then append a fresh timestamp. Without stripping, the URL grows
        // indefinitely and the "base" URL comparison never matches,
        // causing Flutter to treat it as a new network resource but still
        // serve the cached bytes for that path from its HTTP cache.
        final rawUrl = data['profile_picture_url'] as String? ?? '';
        final baseUrl = rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;
        _profilePictureUrl = baseUrl.isNotEmpty
            ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
            : '';

        // ✅ Bump key so BaseProfileTab gets a new ValueKey → full rebuild
        _reloadKey++;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
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
        debugPrint('Update error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: TranslatedText('Update failed: $e'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _switchToPatient() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('users').update({'role': 'patient'}).eq('id', userId);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PatientNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText('Failed to switch: $e'), backgroundColor: Colors.red),
      );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfoColumn(context, 'Email', _email),
            Divider(color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoColumn(context, 'Phone', _phone),
          ],
        ),
      ),
      aboveLogout: [
        Center(
          child: ElevatedButton(
            onPressed: _switchToPatient,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const TranslatedText('Switch to Patient View'),
          ),
        ),
      ],
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
  State<_EditGuardianProfileScreen> createState() => _EditGuardianProfileScreenState();
}

class _EditGuardianProfileScreenState extends State<_EditGuardianProfileScreen> {
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
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
              style: TextStyle(color: colors.primary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildProfileField(context, 'Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            buildProfileField(context, 'Age', _ageController, Icons.cake_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            buildProfileField(context, 'Email', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            buildProfileField(context, 'Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }

  void _save() {
    final updatedName = _nameController.text.trim();
    final updatedEmail = _emailController.text.trim();

    if (updatedName.isEmpty || updatedEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Name and Email are required'), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pop(context, {
      'name': updatedName,
      'age': int.tryParse(_ageController.text.trim()) ?? widget.age,
      'email': updatedEmail,
      'phone': _phoneController.text.trim(),
    });
  }
}