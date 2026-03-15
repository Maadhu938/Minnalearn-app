import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import 'matching_game_screen.dart';
import 'memory_cards_screen.dart';
import 'typing_test_screen.dart';
import 'word_catch_screen.dart';

class LessonGamesScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonGamesScreen({Key? key, required this.lesson}) : super(key: key);

  bool get _hasMatchingWords => lesson.vocabulary.length >= 5;
  bool get _hasMemoryWords => lesson.vocabulary.length >= 4;
  bool get _hasTypingWords => lesson.vocabulary.isNotEmpty;
  bool get _hasWordCatchWords => lesson.vocabulary.length >= 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF472B6),
                    Color(0xFFEC4899),
                    Color(0xFFE11D48),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Back',
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lesson ${lesson.id} Games',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lesson.vocabulary.length} words ready for practice',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.count(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _buildGameCard(
                    context,
                    title: 'Match Game',
                    description: _hasMatchingWords ? 'Match kana with meanings' : 'Need at least 5 words',
                    icon: LucideIcons.shuffle,
                    colors: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                    isLocked: !_hasMatchingWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MatchingGameScreen(lesson: lesson)),
                    ),
                  ),
                  _buildGameCard(
                    context,
                    title: 'Memory Cards',
                    description: _hasMemoryWords ? 'Match kana cards and clear the board' : 'Need at least 4 words',
                    icon: LucideIcons.brain,
                    colors: const [Color(0xFFC084FC), Color(0xFFA855F7)],
                    isLocked: !_hasMemoryWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MemoryCardsScreen(lesson: lesson)),
                    ),
                  ),
                  _buildGameCard(
                    context,
                    title: 'Typing Test',
                    description: _hasTypingWords ? 'Type the English meaning fast' : 'Add words to unlock',
                    icon: LucideIcons.keyboard,
                    colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                    isLocked: !_hasTypingWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TypingTestScreen(lesson: lesson)),
                    ),
                  ),
                  _buildGameCard(
                    context,
                    title: 'Word Catch',
                    description: _hasWordCatchWords ? 'Tap the right falling kana in time' : 'Need at least 4 words',
                    icon: LucideIcons.sparkles,
                    colors: const [Color(0xFFFB923C), Color(0xFFF97316)],
                    isLocked: !_hasWordCatchWords,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WordCatchScreen(lesson: lesson)),
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
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.7 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors[1].withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? LucideIcons.lock : icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
