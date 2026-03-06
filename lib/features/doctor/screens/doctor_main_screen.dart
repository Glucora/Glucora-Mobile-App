import 'package:flutter/material.dart';
import 'doctor_patients_screen.dart';
import 'doctor_requests_screen.dart';
import 'doctor_alerts_screen.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart'; // for logout

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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2BB6A3),
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

  const _EditDoctorProfileScreen({
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  State<_EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<_EditDoctorProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age.toString());
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E)),
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
        child: ListView(
          children: [
            _buildField('Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField('Age', _ageController, Icons.cake_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Email', _emailController, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneController, Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('Address', _addressController, Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
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
    });
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
  String _name = "Dr. Nouran";
  int _age = 45;
  String _email = "Nouran@gmail.com";
  String _phone = "01118027001";
  String _address = "123 Medical Center, Cairo";

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
                    child: const Icon(Icons.person_rounded,
                        size: 48, color: Colors.white),
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
                            color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _editProfile,
                        child: const Icon(Icons.edit,
                            size: 18, color: Color(0xFF199A8E)),
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
            // Contact information card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha:0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  _infoRow(Icons.email_outlined, "Email", _email),
                  const Divider(height: 16, color: Color(0xFFEEEEEE)),
                  _infoRow(Icons.phone_outlined, "Phone", _phone),
                  const Divider(height: 16, color: Color(0xFFEEEEEE)),
                  _infoRow(Icons.location_on_outlined, "Address", _address),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF199A8E)),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
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
        builder: (_) => _EditDoctorProfileScreen(
          name: _name,
          age: _age,
          email: _email,
          phone: _phone,
          address: _address,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _name = result['name'];
        _age = result['age'];
        _email = result['email'];
        _phone = result['phone'];
        _address = result['address'];
      });
    }
  }
}