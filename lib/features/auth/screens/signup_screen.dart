import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'role_selection_screen.dart';
import 'terms_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'login_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _phoneError;

  Future<void> _signUp() async {
    setState(() => _phoneError = null);

    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('You must agree to the Terms of Service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final fullName = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 0;
      final address = _addressController.text.trim();
      final password = _passwordController.text;

      // Check if phone number already exists
      final existingPhone = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('phone_no', phone)
          .maybeSingle();

      if (!mounted) return;

      if (existingPhone != null) {
        setState(() {
          _phoneError = 'This phone number is already in use';
          _isLoading = false;
        });
        return;
      }

      // Check if email already exists
      final existingEmail = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (existingEmail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('This email is already registered'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 1. Sign up with Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      debugPrint('[CREATE USER STATUS] ${response.user.toString()}');

      if (!mounted) return;

      if (response.user != null) {
        // 2. Insert into your custom users table
        final user = response.user!;
/* 
        final insertData = {
          'id': user.id,
          'full_name': fullName,
          'email': email,
          'phone_no': phone,
          'age': age,
          'address': address,
          'role': 'norole',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        print('Inserting user data: $insertData');
 */
        // update the row the trigger already created
        await Supabase.instance.client
            .from('users')
            .update({
              'full_name': fullName,
              'email': email,
              'phone_no': phone,
              'age': age,
              'address': address,
              'role': 'norole',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        if (!mounted) return;

        // Navigate to role selection on success
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
        );
      } else {
        // User needs email confirmation
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignUpSuccessScreen()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      print('Auth error: ${e.message}');

      if (e.message.contains('User already registered')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText(
              'This email is already registered. Please login.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      print('Sign up error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('Sign up failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: TranslatedText(
          'Sign Up',
          style: TextStyle(color: colors.textPrimary),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter your name',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  final nameRegex = RegExp(r'^[a-zA-Z ]+$');
                  if (!nameRegex.hasMatch(value)) {
                    return 'Please enter a valid name (letters and spaces only)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter your email';
                  if (!value.contains('@')) return 'Enter a valid email';
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
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter your password';
                  if (value.length < 8)
                    return 'Password must be at least 8 characters';
                  final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                  final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
                  final hasDigit = RegExp(r'[0-9]').hasMatch(value);
                  final hasSpecial = RegExp(
                    r'[!@#\$%^&*(),.?":{}|<>]',
                  ).hasMatch(value);
                  if (!hasUppercase ||
                      !hasLowercase ||
                      !hasDigit ||
                      !hasSpecial) {
                    return 'Password must include uppercase, lowercase,\nnumber, and special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Enter your phone number',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.phone, color: colors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter your phone number';
                  final numberRegex = RegExp(r'^[0-9]+$');
                  if (!numberRegex.hasMatch(value))
                    return 'Please enter a valid number (numbers only)';
                  if (value.length < 10)
                    return 'Please enter a valid phone number';
                  if (_phoneError != null) return _phoneError;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Age field
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter your age',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.cake_outlined, color: colors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter your age';
                  final age = int.tryParse(value);
                  if (age == null) return 'Please enter a valid number';
                  if (age < 0 || age > 100)
                    return 'Please enter a valid age (0–100)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Address field
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Enter your address',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: colors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter your address';
                  if (value.length < 5) return 'Please enter a valid address';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Terms & Conditions
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) =>
                        setState(() => _agreeToTerms = value ?? false),
                    activeColor: colors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: colors.accent,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsScreen(),
                                ),
                              ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: colors.accent,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsScreen(),
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Sign Up button
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const TranslatedText(
                        'Sign Up',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              // Link to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TranslatedText(
                    "Already have an account? ",
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: TranslatedText(
                      'Login',
                      style: TextStyle(
                        color: colors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// Success screen
class SignUpSuccessScreen extends StatelessWidget {
  const SignUpSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: colors.accent, size: 100),
            const SizedBox(height: 24),
            TranslatedText(
              'Success!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 16),
            const TranslatedText(
              'Your account has been successfully registered',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TranslatedText(
              'Please check your email to confirm your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const TranslatedText(
                'Go to Login',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
