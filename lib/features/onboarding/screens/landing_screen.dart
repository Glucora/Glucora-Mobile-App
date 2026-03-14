import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/features/auth/signup_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:glucora_ai_companion/features/auth/terms_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color _teal = Color(0xFF2BB6A3);

  void _goToLogin(BuildContext context) =>
      Navigator.pushNamed(context, '/login-screen');

  void _goToSignUp(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SignUpScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top half — logo centered
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/Glucora_logo.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'Your glucose. Your insulin.\nAlways under control.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7C7C),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom half — buttons
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Create an account button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _goToSignUp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Create an account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Log in button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => _goToLogin(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(
                            color: Color(0xFFB2DFDB),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Clickable Terms & Privacy Policy text
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        children: [
                          const TextSpan(
                            text: 'By continuing you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: Color(0xFF2BB6A3),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Color(0xFF2BB6A3),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
