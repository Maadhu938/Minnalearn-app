import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import 'matching_game_screen.dart';
import 'true_or_false_screen.dart';
import 'typing_test_screen.dart';

class LessonGamesScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonGamesScreen({Key? key, required this.lesson}) : super(key: key);

  bool get _hasMatchingWords => lesson.vocabulary.length >= 5;
  bool get _hasMemoryWords => lesson.vocabulary.length >= 4;
  bool get _hasTypingWords => lesson.vocabulary.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
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
                  Positioned(
                    right: -10,
                    bottom: -15,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.08,
                        child: Text(
                          '遊',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 104,
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
                      bottom: 40,
                      left: 20,
                      right: 20,
                    ),
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
                              borderRadius: BorderRadius.circular(16),
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
                                  'Back',
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
                        const SizedBox(height: 20),
                        Text(
                          'Lesson ${lesson.id} Games',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lesson.vocabulary.length} words ready for practice',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
                children: [
                  _buildGameCard(
                    context,
                    title: 'Match Game',
                    description: _hasMatchingWords
                        ? 'Match kana with meanings'
                        : 'Need at least 5 words',
                    icon: LucideIcons.shuffle,
                    colors: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                    isLocked: !_hasMatchingWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchingGameScreen(lesson: lesson),
                      ),
                    ),
                  ),
                  _buildGameCard(
                    context,
                    title: 'True or False',
                    description: _hasMemoryWords
                        ? 'Quick-fire kana challenge'
                        : 'Need at least 4 words',
                    icon: LucideIcons.checkCheck,
                    colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    isLocked: !_hasMemoryWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TrueOrFalseScreen(lesson: lesson),
                      ),
                    ),
                  ),
                  _buildGameCard(
                    context,
                    title: 'Typing Test',
                    description: _hasTypingWords
                        ? 'Type the English meaning fast'
                        : 'Add words to unlock',
                    icon: LucideIcons.keyboard,
                    colors: const [Color(0xFF10B981), Color(0xFF059669)],
                    isLocked: !_hasTypingWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TypingTestScreen(lesson: lesson),
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

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required List<Color> colors,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      scaleFactor: 0.95,
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors[1].withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLocked ? LucideIcons.lock : icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.arrowUpRight,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
