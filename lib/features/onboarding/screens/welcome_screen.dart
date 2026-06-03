// lib/features/onboarding/screens/welcome_screen.dart
import 'dart:math' as math;   // for math.pi and math.cos/sin
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/features/onboarding/screens/onboarding_language_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

//StatefulWidget because this screen has animations that change over time.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
//TickerProviderStateMixin is required when you have multiple AnimationControllers in one widget. It supplies the "vsync" (sync to screen refresh rate) for each controller.
    with TickerProviderStateMixin {
      //late lets you declare a variable without initializing it immediately, because the value (vsync: this) only becomes available later in initState().
  late AnimationController _masterController; // one-shot entry animation
  late AnimationController _floatController;  // logo floating up/down
  late AnimationController _pulseController; // background blobs pulsing
  late AnimationController _orbitController; // particles orbiting

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
      duration: const Duration(milliseconds: 1800), //Plays once on load, drives all entry animations
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), 
    )..repeat(reverse: true); //Repeats forever, reverses (up → down → up)


    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400), //Repeats forever, reverses (grow → shrink → grow)
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(); //Repeats forever, no reverse (full 360° loop)

//Entry animations driven by the master
//These all use Interval, which means they only animate during a slice of the master timeline (0.0 to 1.0):
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut), // 0.5 → 1.0, interval 0.0–0.45, elasticOut (bouncy)
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut), // 0.0 → 1.0, interval 0.0–0.25
      ),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),// slides in from below, interval 0.3–0.65
          ),
        );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut), // 0.0 → 1.0, interval 0.3–0.55
      ),
    );

    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic), // slightly after title
          ),
        );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.45, 0.65, curve: Curves.easeOut), // feature pills fade in, interval 0.6–0.85
      ),
    );

    _pillsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),  // slightly after title
      ),
    );

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic), // feature pills fade in, interval 0.6–0.85
          ),
        );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),// button slides in last, interval 0.7–1.0
      ),
    );

    _float = Tween<double>(begin: -8.0, end: 8.0).animate( // -8.0 → 8.0 (pixels), easeInOut, forever → logo bobs up/down
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),  // 0.95 → 1.05 (scale), easeInOut, forever → blobs breathe
    );

    _orbit = Tween<double>( // 0 → 2π (radians), linear, forever → particles rotate
      begin: 0,
      end: 2 * math.pi,
    ).animate(_orbitController);

    _masterController.forward(); //This is where all controllers and animations are created and configured. At the end:
  }

  @override
  void dispose() { // dispose controllers when the widget is removed from the tree, to free memory and stop background tickers.
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
          //positions of the 3 big circles 
          Positioned(  // top-right, partially off screen
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) => Transform.scale(
                scale: _pulse.value, //istening to _pulseController, so they scale with _pulse.value — they "breathe."
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
          Positioned(// mid-left, partially off screen
            bottom: size.height * 0.22,
            left: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) => Transform.scale(
                scale: 1.1 - (_pulse.value - 0.95), //istening to _pulseController, so they scale with _pulse.value — they "breathe."
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
          Positioned( // bottom-right, static
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
            builder: (_, _) {
              return Stack(
                children: List.generate(5, (i) { //generates 5 circles
                  final angle = _orbit.value + (i * 2 * math.pi / 5); //angle of orbiting
                  final radius = 170.0;
                  final cx = size.width / 2 + math.cos(angle) * radius;
                  final cy = size.height * 0.38 + math.sin(angle) * radius; //They orbit around the logo's center (size.height * 0.38).
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
                const Spacer(flex: 2), // pushes content down from the top.

                // Logo with glow ring + float animation
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _masterController,
                    _floatController,
                    _pulseController,
                  ]),
                  builder: (_, _) => Transform.translate(
                    offset: Offset(0, _float.value), // bobs up/down
                    child: FadeTransition(
                      opacity: _logoOpacity,   // entry fade
                      child: ScaleTransition(
                        scale: _logoScale,  // entry scale (bouncy)
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
                            ClipRRect( //The actual logo image (Image.asset)
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
                      child: TranslatedText(
                        'Welcome to Glucora',  //ShaderMask → LinearGradient(accent → primary)
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
                      child: TranslatedText(
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
                FadeTransition( //widgets, fading in together.
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
                const Spacer(flex: 2), //pushes button to the bottom.

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
                       TranslatedText(
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
         TranslatedText (
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

class _GetStartedButton extends StatefulWidget { //StatefulWidget because it has its own press animation.
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
    _pressScale = Tween<double>( //On onTapDown → shrinks to 96%. On onTapUp → springs back, then navigates.
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
          Navigator.pushReplacement( //pushReplacement means the Welcome screen is removed from the stack — the user can't go back to it.
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, _) =>
                  const OnboardingLanguageScreen(),
              transitionsBuilder: (_, animation, _, child) {
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
              const TranslatedText(
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
