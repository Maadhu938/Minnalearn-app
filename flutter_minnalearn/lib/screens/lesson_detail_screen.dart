import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/lesson.dart';
import '../widgets/stat_card.dart';
import 'flashcards_screen.dart';
import 'vocabulary_list_screen.dart';
import 'quiz_screen.dart';
import 'grammar_screen.dart';
import '../services/database_service.dart';

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
    final updated = lessons.firstWhere((l) => l.id == _currentLesson.id);
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Pink gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 80, left: 24, right: 24),
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
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
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
                    'Lesson ${_currentLesson.id}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentLesson.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _currentLesson.title,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.bookOpen,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats cards
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: '${_currentLesson.vocabulary.length}',
                        label: 'Words',
                        bgColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        value: '${(_currentLesson.progress * 100).round()}%',
                        label: 'Progress',
                        bgColor: Colors.purple.shade50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        value: estimatedMinutes == 0 ? '--' : '${estimatedMinutes}m',
                        label: 'Est. Time',
                        bgColor: Colors.pink.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Activity cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Activities',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0, // Increased height to prevent text overflow
                    children: [
                      _buildActivityCard(
                        context,
                        'Flashcards',
                        LucideIcons.bookOpen,
                        Colors.blue.shade50,
                        Colors.blue.shade500,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FlashcardsScreen(lesson: _currentLesson),
                            ),
                          );
                          _refreshLesson();
                        },
                      ),
                      _buildActivityCard(
                        context,
                        'Learn Mode',
                        LucideIcons.sparkles,
                        Colors.purple.shade50,
                        Colors.purple.shade500,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VocabularyListScreen(lesson: _currentLesson),
                            ),
                          );
                          _refreshLesson();
                        },
                      ),
                      _buildActivityCard(
                        context,
                        'Test Mode',
                        LucideIcons.target,
                        Colors.green.shade50,
                        Colors.green.shade500,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(lesson: _currentLesson),
                            ),
                          );
                          _refreshLesson();
                        },
                      ),
                      _buildActivityCard(
                        context,
                        'Grammar',
                        LucideIcons.book,
                        Colors.orange.shade50,
                        Colors.orange.shade500,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GrammarScreen(lesson: _currentLesson),
                            ),
                          );
                          _refreshLesson();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Start lesson button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFE11D48)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FlashcardsScreen(lesson: _currentLesson),
                            ),
                          );
                          _refreshLesson();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(
                          'Start Lesson',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
