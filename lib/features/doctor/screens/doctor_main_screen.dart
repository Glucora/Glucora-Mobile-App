import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'doctor_patients_screen.dart';
import 'doctor_requests_screen.dart';
import 'doctor_alerts_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DoctorPatientsScreen(),
    const DoctorRequestsScreen(),
    const DoctorAlertsScreen(),
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
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
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
  final String specialty; // Add this
  final String license;   // Add this

  const _EditDoctorProfileScreen({
    super.key,
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
    required this.specialty, // Add this
    required this.license,   // Add this
  });

  @override
  State<_EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<_EditDoctorProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;      // Added for age
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
    
    // Use the actual data passed from the profile tab
    _specialityController = TextEditingController(text: widget.specialty);
    _licenseController = TextEditingController(text: widget.license);
  }


  @override
  void dispose() {
    // Always dispose every controller you created in initState
    _nameController.dispose();
    _ageController.dispose();
    _specialityController.dispose(); // Changed from _emailController
    _licenseController.dispose();    // Added new controller
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
        title: Text(
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
            child: Text(
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
            _buildField(context, 'Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            // NEW AGE FIELD
            _buildField(
              context, 
              'Age', 
              _ageController, 
              Icons.cake_outlined, 
              keyboardType: TextInputType.number
            ),
            const SizedBox(height: 16),
            _buildField(context, 'Speciality', _specialityController, Icons.medical_services_outlined),
            const SizedBox(height: 16),
            _buildField(context, 'License Number', _licenseController, Icons.badge_outlined),
            const SizedBox(height: 16),
            _buildField(context, 'Clinic Phone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField(context, 'Clinic Address', _addressController, Icons.location_on_outlined),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
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
      'age': int.tryParse(_ageController.text.trim()) ?? 0, // Ensure it's an int
      'speciality': _specialityController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'phone_no': _phoneController.text.trim(),
      'clinic_address': _addressController.text.trim(),
    });
  }
}

// ─────────────────────────────────────────────────────
// Doctor's Profile Tab (editable, with address)
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
  bool _isLoading  = true;

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
        .select('full_name, phone_no, email, doctor_profile(age, clinic_address, liscense_number, speciality)') // Added speciality
        .eq('id', user.id)
        .single();

    setState(() {
      _name = response['full_name'] ?? "Unknown Doctor";
      _phone = response['phone_no'] ?? "No Phone";
      _email = response['email'] ?? "";

      final dynamic profileData = response['doctor_profile'];
      if (profileData != null) {
        final profile = (profileData is List) ? profileData.first : profileData;
        _age = (profile['age'] as num?)?.toInt() ?? 0;
        _address = profile['clinic_address'] ?? "No Address Set";
        _license = profile['liscense_number'] ?? "Not Set";
        // Ensure this key matches your DB column exactly (speciality vs specialty)
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
        title: const Text('Log Out'),
        content: const Text('Are you sure to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Profile",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
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
                      Text(
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
                  Text(
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
                border: Border.all(color: const Color(0xFFEEEEEE)),
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
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      _infoRow(context, Icons.phone_outlined, "Phone", _phone),
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      _infoRow(context, Icons.badge_outlined, "License", _license),
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      _infoRow(context, Icons.medical_services_outlined, "Specialty", _specialty),
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      _infoRow(context, Icons.location_on_outlined, "Address", _address),
                    ],
              ),
            ),

            // ========== DARK MODE TOGGLE ==========
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(color: colors.textPrimary),
              ),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeThumbColor: colors.primary,
              contentPadding: EdgeInsets.zero,
            ),

            // ========== END DARK MODE TOGGLE ==========
            const SizedBox(height: 24),
            Text(
              "FAQs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _faqItem(context, "How do I connect my glucose monitor?"),
            _faqItem(context, "What do the glucose ranges mean?"),
            _faqItem(context, "Can I share data with my doctor?"),
            _faqItem(context, "How accurate are the predictions?"),
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
                  child: Text(
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
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
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

  Widget _faqItem(BuildContext context, String question) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              question,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
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
        specialty: _specialty, // Pass the local state variable
        license: _license,     // Pass the local state variable
      ),
    ),
  );

  if (result != null) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    setState(() => _isLoading = true);

    try {
      // 1. Update 'users' table
      await supabase.from('users').update({
        'full_name': result['full_name'],
        'phone_no': result['phone_no'],
      }).eq('id', userId!);

      // 2. Update 'doctor_profile' table
      await supabase.from('doctor_profile').update({
        'age': result['age'],
        'clinic_address': result['clinic_address'],
        'speciality': result['speciality'],
        'liscense_number': result['license_number'], // Matches your schema typo
      }).eq('user_id', userId);

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': result['full_name'],
            'phone': result['phone_no'],
            // You can even sync the role if you want
            'role': 'doctor', 
          },
        ),
      );

      // 3. Reload data to refresh UI
      await _loadProfileData();
    } catch (e) {
      debugPrint("Update error: $e");
    } finally {
      setState(() => _isLoading = false);
    }

    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green, // Optional: makes it look better
      ),
    );
  }
  }
}}
