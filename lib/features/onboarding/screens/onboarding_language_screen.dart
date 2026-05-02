// lib/features/onboarding/screens/onboarding_language_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/localization_service.dart';

class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() => _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  String? _switching;
  String _selectedLanguageCode = 'en';
  bool _isTranslating = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    final service = Provider.of<LocalizationService>(context, listen: false);
    _selectedLanguageCode = service.currentLanguageCode;
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(LocalizationService service, String code) async {
    if (code == _selectedLanguageCode || _isTranslating) return;
    
    setState(() {
      _switching = code;
      _isTranslating = true;
    });
    
    await service.changeLanguage(code);
    
    if (mounted) {
      setState(() {
        _selectedLanguageCode = code;
        _switching = null;
        _isTranslating = false;
      });
    }
  }

  void _continue() {
    if (_isTranslating) return; // Don't allow continue while translating
    Navigator.pushReplacementNamed(context, '/who-we-are');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = context.watch<LocalizationService>();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/Glucora_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Your Language',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred language for the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Show loading indicator while translating
            if (_isTranslating)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colors.accent),
                      const SizedBox(height: 16),
                      Text(
                        'Applying language...',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: kSupportedLocales.length,
                  itemBuilder: (context, index) {
                    final locale = kSupportedLocales[index];
                    final isSelected = locale.code == _selectedLanguageCode;
                    final isSwitching = _switching == locale.code;

                    final animation = Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _listController,
                        curve: Interval(
                          index * 0.1,
                          (index * 0.1 + 0.4).clamp(0.0, 1.0),
                          curve: Curves.easeOutBack,
                        ),
                      ),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, 20 * (1 - animation.value)),
                        child: Opacity(opacity: animation.value, child: child),
                      ),
                      child: _LanguageTile(
                        locale: locale,
                        isSelected: isSelected,
                        isSwitching: isSwitching,
                        colors: colors,
                        onTap: () => _selectLanguage(service, locale.code),
                      ),
                    );
                  },
                ),
              ),

            // Continue Button - disable while translating
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isTranslating ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isTranslating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final GlucoraLocale locale;
  final bool isSelected;
  final bool isSwitching;
  final dynamic colors;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.locale,
    required this.isSelected,
    required this.isSwitching,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSwitching ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.4)
                : colors.textSecondary.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.3)
                      : colors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Text(locale.flag, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.nativeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locale.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSwitching)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            else if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}