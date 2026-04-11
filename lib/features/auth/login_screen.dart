// lib\features\auth\login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/features/admin/screens/admin_main_screen.dart';
import 'package:glucora_ai_companion/features/doctor/screens/doctor_main_screen.dart';
import 'package:glucora_ai_companion/features/guardian/screens/guardian_main_screen.dart';
import 'package:glucora_ai_companion/features/user/patient_navigation.dart';
import 'signup_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/location_service.dart';
import 'package:glucora_ai_companion/services/notifications_service.dart';
import 'package:glucora_ai_companion/services/translated_text.dart';


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
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;
  bool _didNavigateAfterAuth = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) async {
      if (!mounted) return;

      if ((event.event == AuthChangeEvent.signedIn ||
              event.event == AuthChangeEvent.initialSession ||
              event.event == AuthChangeEvent.tokenRefreshed) &&
          event.session != null) {
        await _navigateByRole(event.session?.user);
      }
    });
  }
  Future<void> _navigateByRole(User? user) async {
    if (!mounted || _didNavigateAfterAuth || user == null) return;

    try {
      // ✅ Use maybeSingle instead of single — won't throw if row missing
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      // ✅ If no row exists, fall back to auth metadata role
      String normalizedRole = '';

      if (response != null && response['role'] != null) {
        normalizedRole = (response['role'] as String).trim().toLowerCase();
      } else {
        // Try user metadata as fallback
        final metaRole = user.userMetadata?['role']?.toString() ??
            user.appMetadata['role']?.toString() ?? '';
        normalizedRole = metaRole.trim().toLowerCase();
      }

      // ✅ If still no role, create the user row and send to role selection
      if (normalizedRole.isEmpty || normalizedRole == 'norole') {
        // Upsert a basic users row so future logins work
        await Supabase.instance.client.from('users').upsert({
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? '',
          'role': 'norole',
        });

        _didNavigateAfterAuth = true;
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/role-selection', (route) => false);
        return;
      }

      Widget? targetScreen;
      if (normalizedRole == 'patient') {
        try {
          LocationService.startSharingLocation(user.id);
        } catch (e) {
          print('Could not start location: $e');
        }
        targetScreen = const PatientNavigation();
      } else if (normalizedRole == 'doctor') {
        targetScreen = const DoctorMainScreen();
      } else if (normalizedRole == 'guardian') {
        targetScreen = const GuardianMainScreen();
      } else if (normalizedRole == 'admin') {
        targetScreen = const AdminMainScreen();
      }

      if (!mounted) return;
      _didNavigateAfterAuth = true;

      try {
        await NotificationService.saveTokenToSupabase();
      } catch (e) {
        print('Notification token save failed: $e'); // ✅ don't block login
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => targetScreen ?? const SignUpScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Login error: $e'); // ✅ print actual error for debugging
      if (mounted) {
        _showErrorSnackBar('Could not load user role: $e');
      }
    }
  }
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.session == null) {
        _showErrorSnackBar(
          'Login requires a verified email. Check your inbox and try again.',
        );
        return;
      }

      await _navigateByRole(response.user);
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (_) {
      _showErrorSnackBar('Login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.glucora.companion://login-callback',
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (_) {
      _showErrorSnackBar('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: TranslatedText(message), backgroundColor: Colors.red),
    );
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Forgot Password?'),
        content: const TranslatedText(
          'For demo, use one of these:\n'
          'patient@test.com / patient123\n'
          'doctor@test.com / doctor123\n'
          'guardian@test.com / guardian123\n'
          'admin@test.com / admin123',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TranslatedText('OK'),
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
        title: TranslatedText('Login', style: TextStyle(color: colors.textPrimary)),
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
                    prefixIcon: Icon(
                      Icons.email_outlined,
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
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                    child: TranslatedText(
                      'Forgot Password?',
                      style: TextStyle(color: colors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                      : const TranslatedText('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TranslatedText(
                      "Don't have an account? ",
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: TranslatedText(
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
                TranslatedText(
                  'OR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                // Social buttons
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                  label: TranslatedText(
                    'Sign in with Google',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
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
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
