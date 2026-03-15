import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/lesson.dart';
import '../services/quiz_engine.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';

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

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = optionIndex;
      if (_questions[_currentIndex].options[optionIndex] == _questions[_currentIndex].correctAnswer) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
          _selectedOptionIndex = null;
        });
      } else {
        setState(() {
          _showResults = true;
        });
        _updateLessonProgress();
      }
    });
  }

  Future<void> _updateLessonProgress() async {
    double progress = _score / _questions.length;
    // Only update if current performance is better
    if (progress > widget.lesson.progress) {
      await DatabaseService().updateLessonProgress(widget.lesson.id, progress);
    }
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
                    backgroundColor: Colors.grey.shade200,
                    progressColor: Colors.pink,
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
      child: GestureDetector(
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.shade50 : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? LucideIcons.trophy : LucideIcons.award,
                  color: isPassed ? Colors.green : Colors.orange,
                  size: 80,
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
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
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
