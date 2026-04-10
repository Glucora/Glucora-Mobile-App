// lib/features/onboarding/screens/onboarding_language_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/localization_service.dart';

class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late AnimationController _headerController;
  String _selectedLanguageCode = 'en';

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    final service = Provider.of<LocalizationService>(context, listen: false);
    _selectedLanguageCode = service.currentLanguageCode;
  }

  @override
  void dispose() {
    _listController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // ✅ Instant selection — no blocking await, no spinner
  void _selectLanguage(LocalizationService service, String code) {
    if (code == _selectedLanguageCode) return;
    setState(() => _selectedLanguageCode = code);
    // Fire and forget — runs in background
    service.changeLanguage(code);
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, '/who-we-are');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = context.watch<LocalizationService>();

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Subtle background accent blob
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────────
                FadeTransition(
                  opacity: _headerController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/Glucora_logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Choose Your Language',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can always change this later in settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Language list ─────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: kSupportedLocales.length,
                    itemBuilder: (context, index) {
                      final locale = kSupportedLocales[index];
                      final isSelected = locale.code == _selectedLanguageCode;

                      final delay = index * 0.07;
                      final animation = Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _listController,
                          curve: Interval(
                            delay.clamp(0.0, 0.8),
                            (delay + 0.35).clamp(0.0, 1.0),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );

                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, 24 * (1 - animation.value)),
                          child: Opacity(
                              opacity: animation.value.clamp(0.0, 1.0),
                              child: child),
                        ),
                        child: _LanguageTile(
                          locale: locale,
                          isSelected: isSelected,
                          colors: colors,
                          onTap: () => _selectLanguage(service, locale.code),
                        ),
                      );
                    },
                  ),
                ),

                // ── Continue button ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: GestureDetector(
                    onTap: _continue,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [colors.accent, colors.primary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continue',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Tile ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatefulWidget {
  final GlucoraLocale locale;
  final bool isSelected;
  final dynamic colors;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.locale,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _selectController;
  late Animation<double> _selectScale;

  @override
  void initState() {
    super.initState();
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _selectScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_LanguageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _selectController.forward().then((_) => _selectController.reverse());
    }
  }

  @override
  void dispose() {
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.colors.accent.withValues(alpha: 0.09)
              : widget.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? widget.colors.accent.withValues(alpha: 0.45)
                : widget.colors.textSecondary.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.colors.accent.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            // Flag container
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.colors.accent.withValues(alpha: 0.12)
                    : widget.colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? widget.colors.accent.withValues(alpha: 0.25)
                      : widget.colors.textSecondary.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: Text(
                  widget.locale.flag,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Language name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? widget.colors.accent
                          : widget.colors.textPrimary,
                    ),
                    child: Text(widget.locale.nativeName),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.locale.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? widget.colors.accent
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? widget.colors.accent
                      : widget.colors.textSecondary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}