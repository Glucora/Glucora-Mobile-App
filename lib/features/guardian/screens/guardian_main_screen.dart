import 'package:flutter/material.dart';
import 'guardian_home_screen.dart';
import 'guardian_alerts_screen.dart';
import 'guardian_requests_screen.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart'; // for logout
import 'package:flutter_application_1/features/user/patient_navigation.dart'; // <-- IMPORT ADDED

class GuardianMainScreen extends StatefulWidget {
  const GuardianMainScreen({super.key});
  @override
  State<GuardianMainScreen> createState() => _GuardianMainScreenState();
}

class _GuardianMainScreenState extends State<GuardianMainScreen> {
  int _index = 0;

  // Replace with real counts from backend
  static const int _unreadAlerts = 3;
  static const int _pendingRequests = 2;

  final List<Widget> _screens = [
    const GuardianHomeScreen(),
    const GuardianAlertsScreen(),
    const GuardianRequestsScreen(),
    const _GuardianProfileTab(), // replaced placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
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
                _item(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _item(
                  1,
                  Icons.notifications_rounded,
                  Icons.notifications_outlined,
                  'Alerts',
                  badge: _unreadAlerts,
                ),
                _item(
                  2,
                  Icons.people_rounded,
                  Icons.people_outline_rounded,
                  'Requests',
                  badge: _pendingRequests,
                ),
                _item(
                  3,
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profile',
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
    String label, {
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
          color:
              sel
              ? const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.12)
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
                  color: sel ? const Color(0xFF2A9D8F) : Colors.grey.shade400,
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
                        child: Text(
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? const Color(0xFF2A9D8F) : Colors.grey.shade400,
              ),
            ),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF199A8E),
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
            _buildField('Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(
              'Age',
              _ageController,
              Icons.cake_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildField(
              'Email',
              _emailController,
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
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
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF199A8E)),
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
    final updatedName = _nameController.text.trim();
    final updatedAge = int.tryParse(_ageController.text.trim()) ?? widget.age;
    final updatedEmail = _emailController.text.trim();
    final updatedPhone = _phoneController.text.trim();

    Navigator.pop(context, {
      'name': updatedName.isEmpty ? widget.name : updatedName,
      'age': updatedAge,
      'email': updatedEmail.isEmpty ? widget.email : updatedEmail,
      'phone': updatedPhone.isEmpty ? widget.phone : updatedPhone,
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
// Guardian's Profile Tab (editable)
// ─────────────────────────────────────────────────────
class _GuardianProfileTab extends StatefulWidget {
  const _GuardianProfileTab();

  @override
  State<_GuardianProfileTab> createState() => _GuardianProfileTabState();
}

class _GuardianProfileTabState extends State<_GuardianProfileTab> {
  String _name = "Guardian Name";
  int _age = 40;
  String _email = "guardian@example.com";
  String _phone = "01234567890";

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF1616),
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Profile",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFF199A8E),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _editProfile,
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFF199A8E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$_age years",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoColumn("Email", _email),
                  Container(
                    height: 30,
                    width: 1,
                    color: const Color(0xFFEEEEEE),
                  ),
                  _infoColumn("Phone", _phone),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "FAQs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            _faqItem("How do I connect my glucose monitor?"),
            _faqItem("What do the glucose ranges mean?"),
            _faqItem("Can I share data with my doctor?"),
            _faqItem("How accurate are the predictions?"),

            // --- NEW: Switch to Patient button ---
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientNavigation()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF199A8E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Switch to Patient View'),
              ),
            ),
            // --- END NEW ---

            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF1616)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                      color: Color(0xFFEF1616),
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

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _faqItem(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ],
      ),
    );
  }

  void _editProfile() async {
    final result = await Navigator.push(
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
      setState(() {
        _name = result['name'];
        _age = result['age'];
        _email = result['email'];
        _phone = result['phone'];
      });
    }
  }
}