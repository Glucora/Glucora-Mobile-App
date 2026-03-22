import 'package:flutter/material.dart';
import '../../features/admin/screens/admin_main_screen.dart';
import '../../features/doctor/screens/doctor_main_screen.dart';
import '../../features/guardian/screens/guardian_main_screen.dart';
import '../../features/user/patient_navigation.dart';
import 'signup_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  final Map<String, String> _validUsers = {
    'patient@test.com': 'patient123',
    'doctor@test.com': 'doctor123',
    'guardian@test.com': 'guardian123',
    'admin@test.com': 'admin123',
  };

  void _login() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_validUsers.containsKey(email) && _validUsers[email] == password) {
        Widget nextScreen;
        if (email.startsWith('patient')) {
          nextScreen = const PatientNavigation();
        } else if (email.startsWith('doctor')) {
          nextScreen = const DoctorMainScreen();
        } else if (email.startsWith('admin')) {
          nextScreen = const AdminMainScreen();
        } else {
          nextScreen = const GuardianMainScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      } else {
        _showErrorSnackBar('Invalid email or password');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot Password?'),
        content: const Text(
          'For demo, use one of these:\n'
          'patient@test.com / patient123\n'
          'doctor@test.com / doctor123\n'
          'guardian@test.com / guardian123\n'
          'admin@test.com / admin123',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/landing',
              (Route<dynamic> route) => false,
            );
          },
        ),
        title: Text('Login', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Enter your email',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
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
                      borderSide: BorderSide(color: colors.accent, width: 2),
                    ),
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Enter your password',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(Icons.lock_outline, color: colors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: colors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                      borderSide: BorderSide(color: colors.accent, width: 2),
                    ),
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text('Forgot Password?', style: TextStyle(color: colors.accent)),
                  ),
                ),
                const SizedBox(height: 16),
                // Login button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: colors.textSecondary)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'OR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                // Social buttons
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                  label: Text('Sign in with Google', style: TextStyle(color: colors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.apple, color: Colors.black),
                  label: Text('Sign in with Apple', style: TextStyle(color: colors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: colors.textSecondary.withValues(alpha:0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.facebook, color: Colors.blue),
                  label: Text('Sign in with Facebook', style: TextStyle(color: colors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}