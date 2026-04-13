import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'role_selection_screen.dart';
import 'terms_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'login_screen.dart';
import 'package:glucora_ai_companion/services/translated_text.dart';

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


  bool _hasMinLength(String v) => v.length >= 8;
  bool _hasUppercase(String v) => v.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String v) => v.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String v) => v.contains(RegExp(r'[0-9]'));
  bool _hasSpecial(String v) => v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  bool get _passwordIsStrong {
    final v = _passwordController.text;
    return _hasMinLength(v) &&
        _hasUppercase(v) &&
        _hasLowercase(v) &&
        _hasDigit(v) &&
        _hasSpecial(v);
  }


  Future<void> _signUp() async {
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
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'role': 'norole',
          'phone_no': _phoneController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'address': _addressController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignUpSuccessScreen()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // Unique constraint violation on phone_no (code 23505)
      final message = (e.code == '23505' ||
              (e.message.contains('unique') &&
                  e.message.contains('phone_no')))
          ? 'This phone number is already registered. Please use a different number.'
          : 'Sign up failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText(message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Sign up failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Password strength indicator widget ───────────────────────────────────
  Widget _buildPasswordStrengthIndicator() {
    final v = _passwordController.text;
    if (v.isEmpty) return const SizedBox.shrink();

    final rules = [
      (_hasMinLength(v), 'At least 8 characters'),
      (_hasUppercase(v), 'One uppercase letter'),
      (_hasLowercase(v), 'One lowercase letter'),
      (_hasDigit(v), 'One number'),
      (_hasSpecial(v), 'One special character (!@#\$%^&*…)'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules
            .map(
              (r) => Row(
                children: [
                  Icon(
                    r.$1 ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: r.$1 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  TranslatedText(
                    r.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: r.$1 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    InputDecoration fieldDecoration({
      required String label,
      required IconData icon,
      Widget? suffix,
    }) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary),
          prefixIcon: Icon(icon, color: colors.primary),
          suffixIcon: suffix,
          border: border(colors.textSecondary.withValues(alpha: 0.3)),
          enabledBorder: border(colors.textSecondary.withValues(alpha: 0.3)),
          focusedBorder: border(colors.accent, width: 2),
          filled: true,
          fillColor: colors.surface,
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/landing', (_) => false),
        ),
        title: TranslatedText('Sign Up',
            style: TextStyle(color: colors.textPrimary)),
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

              // ── Name ──────────────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: fieldDecoration(
                    label: 'Enter your name', icon: Icons.person_outline),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your name';
                  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v))
                    return 'Letters and spaces only';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────────────────────────
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration(
                    label: 'Enter your email', icon: Icons.email_outlined),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────────────────────────
              StatefulBuilder(
                builder: (context, setLocal) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setLocal(() {}),
                      decoration: fieldDecoration(
                        label: 'Enter your password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colors.textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please enter your password';
                        if (!_passwordIsStrong)
                          return 'Password does not meet the requirements below';
                        return null;
                      },
                    ),
                    _buildPasswordStrengthIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Phone ─────────────────────────────────────────────────────
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: fieldDecoration(
                    label: 'Enter your phone number', icon: Icons.phone),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter your phone number';
                  if (!RegExp(r'^[0-9]+$').hasMatch(v))
                    return 'Numbers only';
                  if (v.length < 10) return 'Please enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Age ───────────────────────────────────────────────────────
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: fieldDecoration(
                    label: 'Enter your age', icon: Icons.cake_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your age';
                  final age = int.tryParse(v);
                  if (age == null) return 'Please enter a valid number';
                  if (age < 13) return 'You must be at least 13 years old';
                  if (age > 100) return 'Please enter a valid age (13–100)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Address ───────────────────────────────────────────────────
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: fieldDecoration(
                    label: 'Enter your address',
                    icon: Icons.location_on_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter your address';
                  if (v.length < 5) return 'Please enter a valid address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Terms checkbox ────────────────────────────────────────────
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (val) =>
                        setState(() => _agreeToTerms = val ?? false),
                    activeColor: colors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 14, color: colors.textSecondary),
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
                                        builder: (_) => const TermsScreen()),
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
                                        builder: (_) => const TermsScreen()),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sign Up button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const TranslatedText('Sign Up',
                        style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),

              // ── Login link ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TranslatedText('Already have an account? ',
                      style: TextStyle(color: colors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: TranslatedText('Login',
                        style: TextStyle(
                            color: colors.accent,
                            fontWeight: FontWeight.bold)),
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

// ── Success screen ────────────────────────────────────────────────────────────
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
            TranslatedText('Success!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.accent)),
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const TranslatedText('Go to Login',
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}