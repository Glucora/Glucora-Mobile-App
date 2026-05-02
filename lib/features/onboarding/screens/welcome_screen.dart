// lib/features/onboarding/screens/welcome_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/features/onboarding/screens/onboarding_language_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _pillsOpacity;
  late Animation<double> _float;
  late Animation<double> _pulse;
  late Animation<double> _orbit;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.45, 0.65, curve: Curves.easeOut),
      ),
    );

    _pillsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );

    _float = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _orbit = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_orbitController);

    _masterController.forward();
  }

  @override
  void dispose() {
    _masterController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.22,
            left: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Transform.scale(
                scale: 1.1 - (_pulse.value - 0.95),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── Orbiting particles ───────────────────────────────────
          AnimatedBuilder(
            animation: _orbit,
            builder: (_, __) {
              return Stack(
                children: List.generate(5, (i) {
                  final angle = _orbit.value + (i * 2 * math.pi / 5);
                  final radius = 170.0;
                  final cx = size.width / 2 + math.cos(angle) * radius;
                  final cy = size.height * 0.38 + math.sin(angle) * radius;
                  final particleSize = 4.0 + (i % 3) * 2.0;
                  return Positioned(
                    left: cx - particleSize / 2,
                    top: cy - particleSize / 2,
                    child: Opacity(
                      opacity: 0.15 + (i % 3) * 0.08,
                      child: Container(
                        width: particleSize,
                        height: particleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i.isEven ? colors.accent : colors.primary,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // ── Main content ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo with glow ring + float animation
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _masterController,
                    _floatController,
                    _pulseController,
                  ]),
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _float.value),
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            Transform.scale(
                              scale: _pulse.value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.accent.withValues(
                                      alpha: 0.15,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            // Inner glow
                            Container(
                              width: 156,
                              height: 156,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.accent.withValues(alpha: 0.08),
                              ),
                            ),
                            // Logo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                'assets/images/Glucora_logo.png',
                                width: 130,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [colors.accent, colors.primary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        'Welcome to Glucora',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // masked by shader
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Your AI-Powered Diabetes Companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Feature pills
                // Replace the existing feature pills section with this:

                // Feature pills - now in a column
                FadeTransition(
                  opacity: _pillsOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FeaturePill(
                          icon: Icons.monitor_heart_outlined,
                          label: 'Track',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        _FeaturePill(
                          icon: Icons.psychology_outlined,
                          label: 'AI Insights',
                          colors: colors,
                          isAccent: true,
                        ),
                        const SizedBox(height: 10),
                        _FeaturePill(
                          icon: Icons.trending_up_rounded,
                          label: 'Improve',
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),

                // Get Started button
                SlideTransition(
                  position: _buttonSlide,
                  child: FadeTransition(
                    opacity: _buttonOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          _GetStartedButton(colors: colors),
                          const SizedBox(height: 20),
                          Text(
                            'Free to start · No credit card needed',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic colors;
  final bool isAccent;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.colors,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAccent
            ? colors.accent.withValues(alpha: 0.12)
            : colors.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isAccent
              ? colors.accent.withValues(alpha: 0.35)
              : colors.textSecondary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isAccent ? colors.accent : colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isAccent ? colors.accent : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Get Started Button ────────────────────────────────────────────────────────

class _GetStartedButton extends StatefulWidget {
  final dynamic colors;
  const _GetStartedButton({required this.colors});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) async {
        await _pressController.reverse();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) =>
                  const OnboardingLanguageScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [widget.colors.accent, widget.colors.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colors.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
