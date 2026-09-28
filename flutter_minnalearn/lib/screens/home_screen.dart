import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/feature_card.dart';
import 'kanji_screen.dart';
import 'kana_screen.dart';
import 'listening_set_selection_screen.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
    DatabaseService.refreshNotifier.addListener(_refresh);
    KanjiScreen.prefetch();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final results = await Future.wait([
      DatabaseService().getLearnedVocabularyCount(),
      DatabaseService().getLearnedKanjiCount(),
      StudyTimerService().getFormattedStudyTime(),
      DatabaseService().getStreak(),
    ]);
    return {
      'vocab': results[0],
      'kanji': results[1],
      'studyTime': results[2],
      'streak': results[3],
    };
  }

  @override
  void dispose() {
    DatabaseService.refreshNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _statsFuture = _fetchStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          color: AppColors.scaffold,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                _buildModernHeader(),

              // Quick Stats Overlapping Cards
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final vocabCount = snapshot.data?['vocab'] ?? 0;
                  final kanjiCount = snapshot.data?['kanji'] ?? 0;
                  final studyTime = snapshot.data?['studyTime'] ?? '0m';

                  return Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              value: vocabCount.toString(),
                              label: 'Words',
                              icon: LucideIcons.bookOpen,
                              bgColor: AppColors.azureLight,
                              accentColor: AppColors.azureDark,
                              onTap: () => widget.onTabChange?.call(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              value: kanjiCount.toString(),
                              label: 'Kanji',
                              icon: LucideIcons.sparkles,
                              bgColor: AppColors.amberLight,
                              accentColor: AppColors.amberDark,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KanjiScreen(),
                                  ),
                                );
                                _refresh();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              value: studyTime.toString(),
                              label: 'Study Time',
                              icon: LucideIcons.clock,
                              bgColor: AppColors.primaryLight,
                              accentColor: AppColors.primaryDark,
                              onTap: () => widget.onTabChange?.call(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kana Quick Access Banner
                    _buildKanaCard(),
                    const SizedBox(height: 20),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Study Modules',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'JLPT N5',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2x2 Feature Cards Grid
                    Builder(
                      builder: (context) {
                        final cardW =
                            (MediaQuery.of(context).size.width - 40 - 14) / 2;
                        final cardH = (cardW * 0.82).clamp(110.0, 148.0);
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Lessons',
                                      subtitle: '25 Minna Units',
                                      icon: LucideIcons.bookOpen,
                                      bgColor: AppColors.azureLight,
                                      iconColor: AppColors.azureDark,
                                      onTap: () => widget.onTabChange?.call(1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Learn Kanji',
                                      subtitle: '100+ Characters',
                                      icon: LucideIcons.sparkles,
                                      bgColor: AppColors.amberLight,
                                      iconColor: AppColors.amberDark,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const KanjiScreen(),
                                          ),
                                        );
                                        _refresh();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Mini Games',
                                      subtitle: '4 Practice Modes',
                                      icon: LucideIcons.gamepad2,
                                      bgColor: AppColors.bambooLight,
                                      iconColor: AppColors.bambooDark,
                                      onTap: () => widget.onTabChange?.call(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Listening Prep',
                                      subtitle: 'Native JLPT Audio',
                                      icon: LucideIcons.headphones,
                                      bgColor: AppColors.coralLight,
                                      iconColor: AppColors.coralDark,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ListeningSetSelectionScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Educational Proverb / Study Tip
                    _buildDailyProverbCard(),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Subtle Japanese watermark
          Positioned(
            right: -10,
            bottom: -15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: Text(
                  '日本語',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 108,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 56,
              bottom: 50,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with Greeting and Streak Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeGreeting(),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        final streak = snapshot.data?['streak'] ?? 0;
                        return BouncingWidget(
                          scaleFactor: 0.92,
                          onTap: () => widget.onTabChange?.call(3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.flame,
                                  color: Color(0xFFFDE047),
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$streak Days',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'MinnaLearn',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Japanese N5 Mastery Journey',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return {'jp': 'おはよう', 'romaji': 'Ohayou', 'icon': 'morning'};
    } else if (hour >= 12 && hour < 18) {
      return {'jp': 'こんにちは', 'romaji': 'Konnichiwa', 'icon': 'day'};
    } else {
      return {'jp': 'こんばんは', 'romaji': 'Konbanwa', 'icon': 'night'};
    }
  }

  Widget _buildTimeGreeting() {
    final greeting = _getTimeGreeting();
    final IconData greetingIcon = greeting['icon'] == 'morning'
        ? LucideIcons.sunrise
        : (greeting['icon'] == 'day' ? LucideIcons.sun : LucideIcons.moon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            greetingIcon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            greeting['jp']!,
            style: GoogleFonts.notoSansJp(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '• ${greeting['romaji']!}',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanaCard() {
    return BouncingWidget(
      scaleFactor: 0.97,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KanaScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppGradients.kanaCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.amberBorder, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.amberDark.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Traditional Kana Emblem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.amberBorder),
                boxShadow: AppShadows.subtle,
              ),
              child: Row(
                children: [
                  Text(
                    'あ',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.amberDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ア',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.coralDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiragana & Katakana',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Master all 46 core kana sounds',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.ink500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amberBorder),
                boxShadow: AppShadows.subtle,
              ),
              child: const Icon(
                LucideIcons.arrowRight,
                color: AppColors.amberDark,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProverbCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink200.withOpacity(0.8), width: 1.2),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bambooLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              color: AppColors.bambooDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kotowaza • Japanese Proverb',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bambooDark,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '継続は力なり (Keizoku wa chikara nari)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perseverance is power. Daily practice leads to fluency.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink500,
                    height: 1.3,
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
