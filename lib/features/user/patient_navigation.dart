import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/features/user/screens/calorie_log_screen.dart';
import 'package:glucora_ai_companion/features/user/screens/home_screen.dart';
import 'package:glucora_ai_companion/features/user/screens/manual_log_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/weekly_report_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/patient_history_screen.dart';
import 'package:glucora_ai_companion/features/guardian/screens/guardian_main_screen.dart';

class PatientNavigation extends StatefulWidget {
  const PatientNavigation({super.key});

  @override
  State<PatientNavigation> createState() => _PatientNavigationState();
}

class _PatientNavigationState extends State<PatientNavigation> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CalorieLogScreen(),
    ManualLogScreen(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.textSecondary.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavTile(
                context,
                icon: Icons.home_rounded,
                label: "Home",
                active: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavTile(
                context,
                icon: Icons.restaurant_menu_rounded,
                label: "Calories",
                active: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavTile(
                context,
                icon: Icons.edit_rounded,
                label: "Manual Log",
                active: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavTile(
                context,
                icon: Icons.person_outline_rounded,
                label: "Profile",
                active: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final BuildContext context;

  const _NavTile(
    this.context, {
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = this.context.colors;
    final color = active ? colors.primary : colors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileScreen extends StatefulWidget {
  final String name;
  final int age;
  final String? email; // Made optional
  final String? phone; // Made optional
  final String height;
  final String weight;

  const _EditProfileScreen({
    required this.name,
    required this.age,
    this.email,
    this.phone,
    required this.height,
    required this.weight,
  });

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _emailController; // Added
  late TextEditingController _phoneController; // Added

@override
void initState() {
  super.initState();
  _nameController = TextEditingController(text: widget.name);
  _ageController = TextEditingController(text: widget.age.toString());
  _heightController = TextEditingController(text: widget.height);
  _weightController = TextEditingController(text: widget.weight);
  _emailController = TextEditingController(text: widget.email);
  _phoneController = TextEditingController(text: widget.phone);}


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
        child: Column(
          children: [
            _buildField(context, 'Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            // ADD EMAIL FIELD HERE
            _buildField(
              context, 
              'Email', 
              _emailController, 
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
              const SizedBox(height: 16),
              _buildField(context, 'Height', _heightController, Icons.height, 
              keyboardType: TextInputType.number, suffix: 'cm'),
              const SizedBox(height: 16),
              _buildField(context, 'Weight', _weightController, Icons.monitor_weight_outlined, 
              keyboardType: TextInputType.number, suffix: 'kg'),
              const SizedBox(height: 16),
             _buildField(context, 'Age', _ageController, Icons.cake_outlined, 
              keyboardType: TextInputType.number, suffix: 'years'),
              const SizedBox(height: 16),
              _buildField(context, 'Phone Number', _phoneController, Icons.phone_outlined, 
              keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }


Widget _buildField(
  BuildContext context,
  String label, // This should only be for the Label/Hint
  TextEditingController controller,
  IconData icon, {
  TextInputType keyboardType = TextInputType.text,
  String? suffix,
}) {
  final colors = context.colors;
  return TextField(
    controller: controller, // This holds the actual data (phone value)
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label, // 👈 Make sure 'Phone Number' is only here
      suffixText: suffix,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}


Future<void> _save() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    final newEmail = _emailController.text.trim();
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim(); // 1. Define this variable

    // 2. Update Authentication (Dashboard)
    await supabase.auth.updateUser(
      UserAttributes(
        email: newEmail != user.email ? newEmail : null,
        // This updates the 'raw_user_meta_data' in the Auth tab
        data: {
          'full_name': newName,
          'phone': newPhone, 
        },
      ),
    );

    // 3. Update the Users table
    await supabase
        .from('users')
        .update({
          'full_name': newName,
          'email': newEmail,
          'phone_no': newPhone,
        })
        .eq('id', user.id);

    // 4. Parse and Update Patient Profile
    // The replaceAll ensures we only save numbers even if 'cm' or 'kg' is in the text
    final weightValue = double.tryParse(_weightController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final heightValue = double.tryParse(_heightController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final ageValue = int.tryParse(_ageController.text) ?? 0;

    await supabase
        .from('patient_profile')
        .update({
          'weight_kg': weightValue,
          'height_cm': heightValue,
          'age': ageValue,
        })
        .eq('user_id', user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pass the new data back to the Profile Tab
      Navigator.pop(context, {
        'name': newName,
        'email': newEmail,
        'phone': newPhone, // Return the phone number too
        'age': ageValue,
        'height': "${heightValue.toInt()} cm",
        'weight': "${weightValue.toInt()} kgs",
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose(); // Added

    super.dispose();
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

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
            _settingsCard(
              context,
              icon: Icons.bluetooth_rounded,
              title: 'Bluetooth Pairing',
              subtitle: 'Connect your CGM sensor or pump',
              color: colors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _BluetoothPairingScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _settingsCard(
              context,
              icon: Icons.medical_services_outlined,
              title: 'Doctor Connecting',
              subtitle: 'Find and connect with your doctor',
              color: const Color(0xFF5B8CF5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _DoctorSearchScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(
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
            color: colors.textSecondary.withValues(alpha: 0.2),
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
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

class _BluetoothPairingScreen extends StatelessWidget {
  const _BluetoothPairingScreen();

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
          'Connect Device',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Devices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _deviceTile(context, 'Dexcom G6', '80% battery', true),
              _deviceTile(context, 'Medtronic 780G', '45% battery', false),
              _deviceTile(context, 'Abbott Libre 3', 'Pairing mode', false),
              const SizedBox(height: 24),
              Text(
                'To pair a new device, put it in discovery mode and tap on it.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceTile(
    BuildContext context,
    String name,
    String status,
    bool isConnected,
  ) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth_rounded,
            size: 24,
            color: isConnected ? colors.primary : colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Connected',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pairing with $name...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Pair', style: TextStyle(color: colors.primary)),
            ),
        ],
      ),
    );
  }
}

class _DoctorSearchScreen extends StatefulWidget {
  const _DoctorSearchScreen();

  @override
  State<_DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<_DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _allDoctors = [
    {
      'name': 'Dr. Sarah Ahmed',
      'phone': '0100 123 4567',
      'email': 'sarah.ahmed@hospital.com',
      'address': '15 Nile Street, Cairo',
    },
    {
      'name': 'Dr. Mahmoud Youssef',
      'phone': '0111 234 5678',
      'email': 'mahmoud.y@clinic.com',
      'address': '22 El Tahrir, Alexandria',
    },
    {
      'name': 'Dr. Nouran Adel',
      'phone': '0122 345 6789',
      'email': 'nouran.adel@medical.org',
      'address': '8 Zamalek, Cairo',
    },
    {
      'name': 'Dr. Karim Hassan',
      'phone': '0155 456 7890',
      'email': 'karim.h@diabetes-care.com',
      'address': '44 Maadi, Cairo',
    },
  ];

  List<Map<String, String>> get _filteredDoctors {
    if (_query.isEmpty) return _allDoctors;
    return _allDoctors.where((doc) {
      return doc['name']!.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          'Find a Doctor',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: colors.textSecondary),
                  hintText: 'Search by doctor name...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredDoctors.isEmpty
                  ? Center(
                      child: Text(
                        'No doctors found',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doc = _filteredDoctors[index];
                        return _doctorCard(context, doc);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(BuildContext context, Map<String, String> doctor) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
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
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                child: Text(
                  doctor['name']!.split(' ').map((e) => e[0]).take(2).join(),
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doctor['name']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(context, Icons.phone_outlined, doctor['phone']!),
          const SizedBox(height: 6),
          _detailRow(context, Icons.email_outlined, doctor['email']!),
          const SizedBox(height: 6),
          _detailRow(context, Icons.location_on_outlined, doctor['address']!),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}



class _ProfileTabState extends State<_ProfileTab> {
    String _name = "";
    int _age = 0; 
    String _height = "";
    String _phone = ""; // Add this
    String _email = ""; // Add this
    String _weight = "";

    bool _isLoading = true;
    final supabase = Supabase.instance.client;

    @override
    void initState() {
      super.initState();
      _loadProfile();
    }

Future<void> _loadProfile() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 🔹 Try to get user
    var userData = await supabase
      .from('users')
      .select()
      .eq('id', user.id)
      .maybeSingle();

    // 👉 If user doesn't exist → create it
    userData ??= await supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': 'New User',
      }).select().single();

    // 🔹 Try to get patient profile
  var patientData = await supabase
      .from('patient_profile')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

    // 👉 If patient profile doesn't exist → create it
    patientData ??= await supabase.from('patient_profile').insert({
        'user_id': user.id,
        'height_cm': 0,
        'weight_kg': 0,
      }).select().single();
    // ignore: avoid_print
    print("USER DATA: $userData");
    // ignore: avoid_print
    print("PATIENT DATA: $patientData");
    // ✅ Set UI
    setState(() {
      _name = userData?['full_name'] ?? "No Name";
      _phone = userData?['phone_no'] ?? ""; // Add this
      _email = userData?['email'] ?? ""; // Add this
      
      // Keep only the numbers in the variables for internal logic
      _height = "${patientData?['height_cm'] ?? 0} cm";
      _weight = "${patientData?['weight_kg'] ?? 0} kg";
      _age = (patientData?['age'] ?? 0).toInt();
      _isLoading = false;
    });
  } catch (e) {
    // ignore: avoid_print
    print("Error loading profile: $e");
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
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                Text(
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
                        builder: (_) => const _SettingsScreen(),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoColumn(context, "Height", _height),
                  Container(
                    height: 30,
                    width: 1,
                    color: colors.textSecondary.withValues(alpha: 0.2),
                  ),
                  _infoColumn(context, "Weight", _weight),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Reports & History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeeklyReportScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.2),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.insert_chart_outlined_rounded,
                              color: colors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Weekly Report',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientHistoryScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.2),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5B8CF5,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF5B8CF5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'History & Export',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GuardianMainScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Switch to Guardian View'),
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

  Widget _infoColumn(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
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
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
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
  // 1. Pass all variables to the constructor
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (_) => _EditProfileScreen(
        name: _name,
        age: _age,
        email: _email,
        phone: _phone, // Now this won't be empty in the edit screen!
        height: _height,
        weight: _weight,
      ),
    ),
  );

  // 2. If the user saved, update the local UI variables
  if (result != null) {
    setState(() {
      _name = result['name'];
      _email = result['email'];
      _phone = result['phone'];
      _age = result['age'];
      _height = result['height'];
      _weight = result['weight'];
    });
  }
}

}
