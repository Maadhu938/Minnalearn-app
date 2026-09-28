import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/lesson.dart';
import '../services/quiz_engine.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/audio_service.dart';
import '../services/achievement_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;

  const QuizScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  bool _showResults = false;
  int _questionGeneration = 0;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _questions = QuizEngine().generateQuiz(widget.lesson);
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  void _handleAnswer(int optionIndex) {
    if (_isAnswered) return;

    final generation = _questionGeneration;

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = optionIndex;
      if (_questions[_currentIndex].options[optionIndex] == _questions[_currentIndex].correctAnswer) {
        _score++;
        AudioService().playCorrect();
      } else {
        AudioService().playWrong();
      }
    });

    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && generation == _questionGeneration) {
          setState(() {
            _currentIndex++;
            _isAnswered = false;
            _selectedOptionIndex = null;
          });
        }
      });
    } else {
      setState(() {
        _showResults = true;
      });
      AudioService().playLevelComplete();
      Future(() => _updateLessonProgress());
    }
  }

  Future<void> _updateLessonProgress() async {
    if (_questions.isEmpty) return;
    double progress = _score / _questions.length;
    final bool wasCompleted = widget.lesson.progress >= 1.0;
    // Re-query current progress from database to avoid stale comparison after cloud sync
    final currentLessons = await DatabaseService().getLessons();
    final currentLesson = currentLessons.firstWhere(
      (l) => l.id == widget.lesson.id,
      orElse: () => widget.lesson,
    );
    if (progress > currentLesson.progress) {
      await DatabaseService().updateLessonProgress(widget.lesson.id, progress);
    }
    await DatabaseService().updateStreak();

    if (mounted) {
      await AchievementService().checkAchievements(
        context: context,
        lastScore: (_score / _questions.length * 100).toInt(),
      );
    }

    // Show lesson completion popup when lesson reaches 100% for the first time
    if (progress >= 1.0 && !wasCompleted && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _showLessonCompletionDialog();
      }
    }
  }

  void _showLessonCompletionDialog() {
    AudioService().playLevelComplete();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.trophy, size: 48, color: Colors.green),
              ),
              const SizedBox(height: 20),
              Text(
                'Sugoi desu ne!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lesson ${widget.lesson.id} completed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Yatta!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No questions available for this lesson.', style: GoogleFonts.inter()),
        ),
      );
    }

    if (_showResults) {
      return _buildResultsScreen();
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(LucideIcons.x, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        'Question ${_currentIndex + 1}/${_questions.length}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 24), // Spacer for centering
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 8.0,
                    percent: progress,
                    backgroundColor: AppColors.ink100,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(10),
                  ),
                ],
              ),
            ),

            // Question Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      _getQuestionLabel(currentQuestion.type),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentQuestion.question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Options
                    ...List.generate(currentQuestion.options.length, (index) {
                      return _buildOptionButton(index, currentQuestion);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionLabel(QuestionType type) {
    switch (type) {
      case QuestionType.kanaToEnglish:
        return 'What does this kana word mean?';
      case QuestionType.englishToKana:
        return 'Choose the kana for this meaning:';
    }
  }

  Widget _buildOptionButton(int index, Question question) {
    final optionText = question.options[index];
    final isCorrect = optionText == question.correctAnswer;
    final isSelected = _selectedOptionIndex == index;

    Color borderColor = Colors.transparent;
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF374151);
    Widget? icon;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green.shade400;
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20);
      } else if (isSelected) {
        borderColor = Colors.red.shade400;
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = const Icon(LucideIcons.xCircle, color: Colors.red, size: 20);
      }
    } else {
      borderColor = Colors.grey.shade200;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncingWidget(
        onTap: () => _handleAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  optionText,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (icon != null) icon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    double percentage = (_score / _questions.length) * 100;
    bool isPassed = percentage >= 80;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.shade50 : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  isPassed ? 'assets/gif/Shiba Happy.gif' : 'assets/gif/Shiba Sad.gif',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isPassed ? 'Excellent!' : 'Keep Practicing!',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $_score out of ${_questions.length}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 48),
              _buildStatRow('Accuracy', '${percentage.toInt()}%'),
              const SizedBox(height: 12),
              _buildStatRow('Lesson', 'Lesson ${widget.lesson.id}'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Lessons',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
