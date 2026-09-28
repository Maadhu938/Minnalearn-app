import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/stat_card.dart';
import 'flashcards_screen.dart';
import 'vocabulary_list_screen.dart';
import 'quiz_screen.dart';
import 'grammar_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late Lesson _currentLesson;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
  }

  Future<void> _refreshLesson() async {
    final lessons = await DatabaseService().getLessons();
    final updated = lessons.firstWhere(
      (l) => l.id == _currentLesson.id,
      orElse: () => _currentLesson,
    );
    if (mounted) {
      setState(() {
        _currentLesson = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedMinutes = _currentLesson.vocabulary.isEmpty
        ? 0
        : (_currentLesson.vocabulary.length * 2).clamp(10, 45).toInt();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Pinned Fixed Header ──────────────────────────────────────────────
          _buildPinnedHeader(),

          // ── Scrollable Body with ClampingPhysics (Zero White Space Gaps) ──────
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Quick Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: '${_currentLesson.vocabulary.length}',
                        label: 'Words',
                        icon: LucideIcons.bookOpen,
                        bgColor: AppColors.azureLight,
                        accentColor: AppColors.azureDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        value: '${(_currentLesson.progress * 100).round()}%',
                        label: 'Progress',
                        icon: LucideIcons.award,
                        bgColor: AppColors.amberLight,
                        accentColor: AppColors.amberDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        value: estimatedMinutes == 0 ? '--' : '${estimatedMinutes}m',
                        label: 'Est. Time',
                        icon: LucideIcons.clock,
                        bgColor: AppColors.primaryLight,
                        accentColor: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Section Title
                Text(
                  'Study Activities',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 2x2 Activity Cards Grid
                GridView.count(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.98,
                  children: [
                    _buildActivityCard(
                      context: context,
                      title: 'Flashcards',
                      subtitle: 'Swipe & Audio',
                      icon: LucideIcons.layers,
                      bgColor: AppColors.azureLight,
                      iconColor: AppColors.azureDark,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FlashcardsScreen(lesson: _currentLesson),
                          ),
                        );
                        _refreshLesson();
                      },
                    ),
                    _buildActivityCard(
                      context: context,
                      title: 'Learn Mode',
                      subtitle: 'Vocabulary List',
                      icon: LucideIcons.bookOpen,
                      bgColor: AppColors.amberLight,
                      iconColor: AppColors.amberDark,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VocabularyListScreen(lesson: _currentLesson),
                          ),
                        );
                        _refreshLesson();
                      },
                    ),
                    _buildActivityCard(
                      context: context,
                      title: 'Test Mode',
                      subtitle: '10 Questions',
                      icon: LucideIcons.target,
                      bgColor: AppColors.bambooLight,
                      iconColor: AppColors.bambooDark,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                QuizScreen(lesson: _currentLesson),
                          ),
                        );
                        _refreshLesson();
                      },
                    ),
                    _buildActivityCard(
                      context: context,
                      title: 'Grammar',
                      subtitle: 'Key Patterns',
                      icon: LucideIcons.fileText,
                      bgColor: AppColors.coralLight,
                      iconColor: AppColors.coralDark,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GrammarScreen(lesson: _currentLesson),
                          ),
                        );
                        _refreshLesson();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Primary Start Button
                BouncingWidget(
                  scaleFactor: 0.96,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FlashcardsScreen(lesson: _currentLesson),
                      ),
                    );
                    _refreshLesson();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryHeader,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppShadows.primaryGlow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.play,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Start Study Session',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
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

  Widget _buildPinnedHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BouncingWidget(
                scaleFactor: 0.94,
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lessons',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lesson ${_currentLesson.id}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_currentLesson.title.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _currentLesson.title,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'JLPT N5',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      scaleFactor: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.ink200.withOpacity(0.8),
            width: 1.2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 21,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.ink100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.arrowUpRight,
                    size: 13,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.ink500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
