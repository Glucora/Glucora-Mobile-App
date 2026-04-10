import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/translated_text.dart';

class WhoWeAreScreen extends StatefulWidget {
  const WhoWeAreScreen({super.key});

  @override
  State<WhoWeAreScreen> createState() => _WhoWeAreScreenState();
}

class _WhoWeAreScreenState extends State<WhoWeAreScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _pages = [
    {
      'tag': 'The problem',
      'title': 'Managing Type 1\nDiabetes never stops.',
      'subtitle':
          'Checking glucose, calculating doses, reacting to highs and lows — every day, around the clock.',
      'accentColor': Color(0xFF2BB6A3),
    },
    {
      'tag': 'What we do',
      'title': 'Glucora handles\nthe hard part.',
      'subtitle':
          'It reads your glucose every 5 minutes, predicts where it\'s heading, and delivers the right insulin dose — before a problem happens.',
      'accentColor': Color(0xFF7C4DFF),
    },
    {
      'tag': 'Transparency',
      'title': 'Every decision\nis explained.',
      'subtitle':
          'You\'ll always see what was predicted, why a dose was recommended, and how confident the system was.',
      'accentColor': Color(0xFFFFA000),
    },
    {
      'tag': 'Who it\'s for',
      'title': 'Built for patients,\ncaregivers and doctors.',
      'subtitle':
          'Whether you\'re managing your own health, watching over a child, or reviewing patients — there\'s a view built for your role.',
      'accentColor': Color(0xFF1976D2),
    },
    {
      'tag': 'Safety',
      'title': 'Safety comes\nfirst, always.',
      'subtitle':
          'Every dose passes three checks before delivery. If anything looks off, the system stops and alerts you immediately.',
      'accentColor': Color(0xFF388E3C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/ai-explain');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/ai-explain'),
                    child: TranslatedText(
                      'Skip',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _animController.reset();
                  _animController.forward();
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final p = _pages[index];
                  final accent = p['accentColor'] as Color;
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/Glucora_logo.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(height: 36),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TranslatedText(
                              (p['tag'] as String).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          TranslatedText(
                            p['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 20),

                          TranslatedText
                          (
                            p['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.textSecondary,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? colors.accent : colors.textSecondary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: TranslatedText(
                        _currentPage == _pages.length - 1
                            ? 'How does the AI work?'
                            : 'Next',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}