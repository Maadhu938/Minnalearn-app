import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'auth_screen.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'tag': 'CURATED JLPT N5',
      'title': 'Master 25 Structured Lessons',
      'description':
          'Follow the proven Minna no Nihongo curriculum with 1,000+ vocabulary words, clear grammar points, and native audio.',
      'type': 'lessons',
    },
    {
      'tag': 'AUTHENTIC CHARTS',
      'title': 'Kana & Kanji Complete Charts',
      'description':
          'Learn all 46 Hiragana & Katakana in traditional Gojūon layout, plus 100+ essential N5 Kanji with stroke writing practice.',
      'type': 'kana_kanji',
    },
    {
      'tag': 'RETENTION SYSTEM',
      'title': 'Smart Flashcards & Quizzes',
      'description':
          'Reinforce memory effortlessly with interactive typing tests, matching pairs, sound practice, and daily streak tracking.',
      'type': 'games',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    await DatabaseService().setOnboardingSeen(true);
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Skip & Back)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    BouncingWidget(
                      scaleFactor: 0.92,
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink200),
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          size: 18,
                          color: AppColors.ink700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  // App title
                  Text(
                    'MinnaLearn',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                  // Skip button
                  BouncingWidget(
                    scaleFactor: 0.92,
                    onTap: _finishOnboarding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.ink200),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stylized Educational Graphic
                        _buildHeroVisual(page['type']),
                        const SizedBox(height: 36),
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            page['tag'],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Headline
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                            height: 1.2,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          page['description'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.ink500,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & CTA
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, bottom: 28, top: 10),
              child: Column(
                children: [
                  // Smooth Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 7,
                        width: _currentPage == index ? 24 : 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.ink200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary CTA
                  BouncingWidget(
                    scaleFactor: 0.96,
                    onTap: _isFinishing ? null : _handlePrimaryAction,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryHeader,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isFinishing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentPage == _pages.length - 1 ? 'Start Learning' : 'Continue',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    LucideIcons.arrowRight,
                                    size: 18,
                                    color: Colors.white,
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
      ),
    );
  }

  Widget _buildHeroVisual(String type) {
    if (type == 'lessons') {
      return Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink200, width: 1.2),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '第 1 課',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFamilyFallback: ['Noto Sans CJK JP', 'sans-serif'],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minna Lesson 1',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                      Text(
                        'Vocabulary & Grammar',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.volume2, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'こんにちは • Hello',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: 0.85,
                minHeight: 6,
                backgroundColor: AppColors.ink200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.bamboo),
              ),
            ),
          ],
        ),
      );
    } else if (type == 'kana_kanji') {
      return Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink200, width: 1.2),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildVisualTile('あ', 'a', AppColors.primaryLight, AppColors.primary),
            _buildVisualTile('ア', 'a', AppColors.azureLight, AppColors.azureDark),
            _buildVisualTile('漢', 'kanji', AppColors.amberLight, AppColors.amberDark),
          ],
        ),
      );
    } else {
      // games / retention
      return Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink200, width: 1.2),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.flame, color: AppColors.coral, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '7-Day Streak!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coralDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bambooLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '100% Retained',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bambooDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.ink200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '猫',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                      fontFamilyFallback: ['Noto Sans CJK JP', 'sans-serif'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ねこ (neko) = Cat',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink700,
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

  Widget _buildVisualTile(String character, String sub, Color bg, Color textCol) {
    return Container(
      width: 64,
      height: 76,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textCol.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            character,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textCol,
              fontFamilyFallback: const ['Noto Sans CJK JP', 'sans-serif'],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}
